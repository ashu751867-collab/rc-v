# P43 LEDs, display register and buttons - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of hand drawings (put them next to this file and link them).

## U1 Digital logic
Give the truth table (or state table) of one part of your circuit and the simplified Boolean expression you used. Which gates or flip-flops did you need?

The write-enable part of my circuit: the LED register may only be written when we = 1 and ridx = 0 (register 0).

| we | ridx1 | ridx0 | write_ok |
|----|-------|-------|----------|
| 0  | 0     | 0     | 0 |
| 0  | 0     | 1     | 0 |
| 0  | 1     | 0     | 0 |
| 0  | 1     | 1     | 0 |
| 1  | 0     | 0     | 1 |
| 1  | 0     | 1     | 0 |
| 1  | 1     | 0     | 0 |
| 1  | 1     | 1     | 0 |

Expression: write_ok = we AND (NOT ridx1) AND (NOT ridx0). It is 1 in only one row, so no further simplification is needed.
I used a 2-to-4 decoder (output 0 is 1 only when ridx = 0) and one AND gate. The register needs 8 D flip-flops, and the next value is D = (NOT rst) AND (write_ok ? wdata : old value).

## U2 Digital components
Which building blocks (adders, multiplexers, decoders, registers, memory) does your Digital circuit use, and how are they connected?

My Digital circuit uses:
- one 8-bit D flip-flop (a register) to remember the LED value,
- two 2-to-1 multiplexers in front of it: Mux1 chooses between the old value and wdata (select = write_ok), and Mux2 chooses between Mux1's output and the constant 0 (select = rst), so reset wins over write,
- one 2-to-4 decoder and one AND gate to make write_ok from we and ridx,
- one 4-to-1 multiplexer (Mux3) as the read multiplexer, controlled by ridx. Input 0 is the LED register, input 2 is the buttons, and the unused inputs 1 and 3 are fed with the constant 0,
- three constant 0 inputs in total (one for Mux2 and two for Mux3).
The clock goes to the flip-flop. Its Q output goes to the leds pin, back to Mux1, and to Mux3. I did not need an adder or memory.

## U3 Data representation
Pick three test vectors of your block and explain them in binary, hex and decimal (signed where it matters). Where could overflow or sign extension go wrong?

1. Read of buttons: buttons = 0x1D = 0001 1101 binary = 29 decimal. With ridx = 2 it appears on rdata unchanged. It is positive, so signed and unsigned are the same.
2. Write to the LEDs: wdata = 0xBB = 1011 1011 binary = 187 unsigned (or -69 if read as signed 8-bit). The LEDs only show the bits, so the sign does not matter. Each 1 is a lit LED.
3. Reset row: wdata = 0x1B = 0001 1011 binary = 27 decimal, but rst = 1 (and ridx = 3 is not the LED register anyway), so the register becomes 0 and the 27 is ignored.
Where it could go wrong: in the Verilog the 8-bit buttons value is padded with 24 zero bits ({24'd0, buttons}). If it were sign-extended, 0xBB would become 0xFFFFFFBB, which is wrong. The 16-bit LED register only keeps the lowest 16 bits of the 32-bit wdata, so the higher bits are lost (truncation). There is no addition or subtraction in my block, so arithmetic overflow cannot happen here.

## U4 Computer organisation
In which step of the instruction cycle (fetch, decode, execute, memory, write-back, interrupt) does your block do its work? Which instructions need it?

My block works in the memory step of the instruction cycle. The CPU reaches it with ordinary store and load instructions: sw writes the LEDs or the SEG register, and lw reads the buttons or the LEDs back (the loaded value then goes to the register file in the write-back step). The execute step only computes the address (base register + offset). Instructions that need it: sw and lw. My block does not take part in fetch, decode or interrupts.

## U5 Processors
How would a CISC processor, a stack machine or a GPU do the job of your block differently? (Look at the RISC-V vs Mano comparison in docs/ARCHITECTURE.md.)

In RISC-V (this project) the LEDs are memory-mapped, so a normal lw/sw is used. A CISC processor such as x86 can have special IN and OUT instructions and a separate I/O address space. Mano's basic computer also uses special INP and OUT instructions that work through the accumulator. A stack machine has no general registers: it would push the value and an output operation would take it from the top of the stack. A GPU would drive many outputs in parallel with many threads, usually through a large memory area (like a frame buffer), instead of one 16-bit register.

## U6 Memory and I/O
How does your block take part in a memory access or an I/O transfer? If it does not, explain which neighbouring block does and how data reaches it.

My block is an I/O device using memory-mapped I/O. It is I/O slot 2, with its registers starting at address 0x00020080. The address decoder (P31) sees that address and turns on my sel signal. ridx then picks the register: LEDS (0), SEG (1), BUTTONS (2), and register 15 reads 43. For a write, the CPU's store provides we and wdata. For a read, my rdata goes through the I/O read bus (P33) back to the CPU.

## E1 Instruction trace: AUIPC
Trace one AUIPC instruction through the whole RC-V processor, block by block (use docs/ARCHITECTURE.md and the simulator's --trace output). List the blocks it passes through and the value on the main signals.

Example: AUIPC x5, 0x10 at PC = 0x00000100. The instruction word is 0x00010297 (opcode 0x17, rd = 5, imm[31:12] = 0x00010).

| Step | Block | What happens | Value |
|------|-------|--------------|-------|
| 1 | Program counter register (P14) | holds the address | PC = 0x00000100 |
| 2 | Instruction memory | outputs the instruction | 0x00010297 |
| 3 | Instruction field splitter (P17) | cuts the fields | opcode 0x17, rd 5, imm 0x00010 |
| 4 | Opcode class decoder (P21) | recognises AUIPC (U-type) | class = U-type |
| 5 | Hardwired control unit (P22) | sets A = PC, B = immediate, ALU adds, write register, no memory, next PC = PC + 4 | control signals |
| 6 | Immediate generator B/J/U (P19) and selector (P20) | imm shifted left by 12 | 0x00010000 |
| 7 | ALU operand selector (P26) | picks the operands | A = 0x00000100, B = 0x00010000 |
| 8 | ALU adder (P01) | adds | 0x00010100 |
| 9 | ALU result selector (P08) | passes the adder result | 0x00010100 |
| 10 | Write-back selector (P25) | picks the ALU result, not memory | 0x00010100 |
| 11 | Register-file write decoder (P11) and storage (P12) | writes register x5 | x5 = 0x00010100 |
| 12 | PC incrementer (P03) and next-PC selector (P15) | PC + 4 | next PC = 0x00000104 |

So AUIPC computes rd = PC + (imm << 12).

## E2 Neighbour review
Review the pull requests of P42 (Keyboard input) and P44 (Seven-segment decoder). Paste the links to your review comments here.

- P42 (Keyboard input): when I checked on 13 November 2026 there was no pull request for P42 yet, so I could not review it. I will review it when it appears and add the link here.
- P44 (Seven-segment decoder): when I checked on 13 November 2026 there was no pull request for P44 yet, so I could not review it. I will review it when it appears and add the link here.

## E3 Where my block sits
In two or three sentences: which layer of the computer is your block in (gates / components / datapath / control / instruction set / memory / I/O), which blocks feed it and which blocks use its output?

My block is in the I/O layer. It is fed by the CPU through the address decoder (P31) and the store data (wdata), and by the physical buttons. Its outputs are used by the I/O read bus (P33) for the CPU to read, by the seven-segment decoder (P44) and hex display scanner (P45) through the SEG register, and by the physical LEDs.

## E4 Syllabus map
Tick every syllabus topic your work touched (main units: Unit 2, Unit 6).

- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [x] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [x] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA
