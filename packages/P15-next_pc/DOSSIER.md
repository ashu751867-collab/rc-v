# P15 Next-PC selector - dossier

## U1 Digital logic
The whole circuit is combinational, so there are no flip-flops. I built every 2-to-1 multiplexer from two XOR gates and one AND gate:

| s | a | b | out = a XOR (s AND (a XOR b)) |
|---|---|---|---|
| 0 | 0 | 0 | 0 |
| 0 | 0 | 1 | 0 |
| 0 | 1 | 0 | 1 |
| 0 | 1 | 1 | 1 |
| 1 | 0 | 0 | 0 |
| 1 | 0 | 1 | 1 |
| 1 | 1 | 0 | 0 |
| 1 | 1 | 1 | 1 |

When s = 0 the term (a XOR b) is masked to 0, so out = a. When s = 1 the expression becomes a XOR a XOR b = b. This is the same as out = (NOT s AND a) OR (s AND b). The XOR/AND form needs only 4-bit gates, so one gate handles all four bits at once.

For JALR the result must have bit 0 cleared, so I AND jalr_y with the constant 1110 (decimal 14). In total the circuit uses 12 XOR gates and 7 AND gates (6 for the multiplexers and 1 for the JALR mask).

## U2 Digital components
The circuit uses only gates, splitters and one constant, with no ready-made multiplexer, adder, register or memory. The sel input goes into a splitter that gives three separate bits. Each bit goes into another splitter that copies it four times, so it becomes a 4-bit mask that can control a 4-bit AND gate.

The six 2-to-1 multiplexers are connected as a tree of three levels:
- Level 1, controlled by sel[0]: A = sel[0] ? target : pc4, B = sel[0] ? mtvec : (jalr_y AND 1110), C = sel[0] ? pc4 : mepc.
- Level 2, controlled by sel[1]: A2 = sel[1] ? B : A, and B2 = sel[1] ? pc4 : C.
- Level 3, controlled by sel[2]: npc = sel[2] ? B2 : A2.

Check: sel = 4 (100) gives mepc, sel = 5 (101) gives pc4, and sel = 6 or 7 also gives pc4, as the task asks.

## U3 Data representation
1. Test vector sel = 2, jalr_y = 11. In binary 1011, hex B, decimal 11 (signed 4-bit: -5). Bit 0 is cleared, giving 1010, hex A, decimal 10 (signed -6). The result is correct even for a negative value because only one bit is cleared; no arithmetic is done.
2. Test vector sel = 5, pc4 = 6. In binary 0110, hex 6, decimal 6. The selector value 5 is not defined, so the block falls back to pc4 and npc = 6.
3. Verilog test vector sel = 2, jalr_y = 0x7FFFFFFF (decimal 2147483647). Clearing bit 0 gives 0x7FFFFFFE (decimal 2147483646). Another vector has pc4 = 0x80000000, which is 2147483648 as an unsigned address but -2147483648 if read as signed; the block just passes it through unchanged.

Overflow cannot happen inside this block because it only copies bits. Overflow belongs to the pc+4 adder and the target adder in other blocks. Sign extension also does not apply because all inputs are already full width. The real mistake to avoid is the mask width: in Verilog the mask must be 32'hFFFFFFFE. Writing 32'hE would clear all upper bits as well. In Digital the constant must be 14 (1110), not 15 or 1.

## U4 Computer organisation
The block works in the Next PC step, the last step of the instruction cycle, after fetch, decode, execute, memory and write-back have produced their values. It is used by every instruction, because every instruction needs a next address:
- sel 0 (pc+4): ordinary instructions such as ADD, LW and SW, and branches that are not taken.
- sel 1 (target): taken branches (BEQ, BNE, BLT, ...) and JAL (a function call).
- sel 2 (jalr result): JALR, which is how ret returns from a subroutine.
- sel 3 (mtvec): a trap, meaning an interrupt, ECALL or an illegal instruction.
- sel 4 (mepc): MRET, which returns from a trap.

## U5 Processors
A CISC processor has variable-length instructions, so the next address is pc plus the instruction length, not always +4. It also often updates the PC step by step in microcode, as in Mano's computer, where BUN loads the PC in a separate micro-operation. A stack machine has no registers; a call pushes the return address on the stack and a return pops it, so the next PC comes from the top of the stack instead of a register chosen by JALR. A GPU runs many threads that share one PC, so a branch cannot just pick one next PC. When the threads disagree the GPU runs both paths one after another using masks and rejoins later. RISC-V in RC-V is simpler: one multiplexer picks one of five addresses in one clock.

## U6 Memory and I/O
This block does not read or write data memory or I/O. It only chooses the address of the next instruction, which then goes to the PC register and the ROM (instruction fetch is a read from ROM at 0x00000000 to 0x0000FFFF). Data loads and stores are handled by other blocks: the ALU makes the address, the store align block builds the data and byte enables, the bus arbiter and address decoder send the access to RAM or to the I/O bus, and an I/O device receives it as sel, we, re, ridx and wdata and answers on rdata. For example, my program prints with stores to the terminal register TXDATA, and this block just keeps fetching the next instruction after each store. The block also helps with interrupt-driven I/O: when a device interrupt is taken, sel = 3 sends the PC to the handler in mtvec.

## E1 Instruction trace: SW
I traced `sw t1, 8(t0)` on the RC-V simulator (--trace). It sits at PC 0x00000240, its machine code is 0x0062A423, and before it t0 = x5 = 0x00010000 and t1 = x6 = 0x0000002A.

1. Fetch: the PC register gives 0x00000240 and the ROM returns 0x0062A423. The pc+4 adder gives pc4 = 0x00000244.
2. Decode: the field block splits the word into opcode 0100011 (STORE), funct3 010 (word), rs1 = 5, rs2 = 6. The S-type immediate joins bits imm[11:5] = 0000000 and imm[4:0] = 01000, so imm = 8.
3. Control: the class decoder says STORE and the control word is 0x1210: memwrite = 1, bsel_imm = 1, immsel = 1 (S), regwrite = 0.
4. Register file: reads x5 = 0x00010000 and x6 = 0x0000002A.
5. Execute: the operand selector gives A = 0x00010000 (rs1) and B = 8 (immediate). The ALU adds them and gives the address 0x00010008. (The branch compare and target adder also compute something, but it is not used.)
6. Memory: the store align block sends data 0x0000002A with all four byte enables on. The bus arbiter gives the bus to the processor and the address decoder sees that 0x00010008 is in RAM (0x00010000 to 0x00013FFF). RAM writes the word at the clock edge.
7. Write-back: regwrite = 0, so nothing is written to a register. The trace line shows no register change.
8. Next PC: it is not a branch, jump or trap, so the next-PC logic gives sel = 0 and my P15 block outputs pc4 = 0x00000244. The next trace line indeed starts at PC 0x00000244.

## E2 Neighbour review
- P26 (ALU operand selector): pending submission
- P16 (Next-PC decision logic): pending submission

## E3 Where my block sits
My block is in the datapath layer, at the very end of the instruction cycle, right before the PC register. Its select input comes from the next-PC decision logic (P16, which looks at branch, jump, trap and mret signals), and its data inputs come from the pc+4 adder (P03), the target adder (P02), the ALU result (for JALR) and the CSR registers mtvec and mepc (P37). Its output goes to the PC register (P14), which gives the next fetch address.

## E4 Syllabus map
- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [ ] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [x] Interrupts and the interrupt cycle
- [ ] Pipelining
- [x] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [ ] I/O interface, programmed / interrupt-driven I/O, DMA
