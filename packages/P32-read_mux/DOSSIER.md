# P32 Memory read selector - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic
Give the truth table (or state table) of one part of your circuit and the
simplified Boolean expression you used. Which gates or flip-flops did you need?

Ans : The memory read selector uses three select signals: sel_rom, sel_ram and sel_io.

For each output bit:
rdata[i] = (sel_rom AND rom_d[i]) OR
           (sel_ram AND ram_d[i]) OR
           (sel_io AND io_d[i]).

Truth table for one output bit:

sel_rom sel_ram sel_io | rdata[i]
   0       0       0   |    0
   1       0       0   |  rom_d[i]
   0       1       0   |  ram_d[i]
   0       0       1   |  io_d[i]

The select signals are expected to be one-hot, meaning only one source is selected at a time. The circuit uses AND and OR gates. It does not require flip-flops because it is a combinational circuit.

## U2 Digital components
Which building blocks (adders, multiplexers, decoders, registers, memory)
does your Digital circuit use, and how are they connected?

Ans: My circuit is a combinational data selector. It receives data from ROM, RAM and I/O along with their select signals. AND gates mask the unselected data sources, and OR gates combine the selected data bits to produce the final read data output. It does not use registers or flip-flops.

## U3 Data representation
Pick three test vectors of your block and explain them in binary, hex and
decimal (signed where it matters). Where could overflow or sign extension go wrong?

Ans: Test 1 – ROM selected
sel_rom = 1, sel_ram = 0, sel_io = 0
rom_d = 0x12345678
rdata = 0x12345678
Binary: 00010010 00110100 01010110 01111000
Decimal (unsigned): 305419896

Test 2 – RAM selected
sel_rom = 0, sel_ram = 1, sel_io = 0
ram_d = 0xFFFFFFFF
rdata = 0xFFFFFFFF
Binary: 11111111 11111111 11111111 11111111
Decimal (unsigned): 4294967295
Decimal (signed): -1

Test 3 – I/O selected
sel_rom = 0, sel_ram = 0, sel_io = 1
io_d = 0x80000000
rdata = 0x80000000
Binary: 10000000 00000000 00000000 00000000
Decimal (unsigned): 2147483648
Decimal (signed): -2147483648

Overflow can occur if a value is stored in fewer bits than required. Sign extension can go wrong if a signed value is extended using zero extension instead of sign extension. The selector itself only passes bits and does not perform arithmetic.

## U4 Computer organisation
In which step of the instruction cycle (fetch, decode, execute, memory,
write-back, interrupt) does your block do its work? Which instructions need it?

Ans: My block mainly works during the memory stage of the instruction cycle. When a load instruction reads data, the selector chooses the required data source and forwards it to the processor datapath. The selected data can then be written back to a register. Store instructions do not use this read path in the same way.

## U5 Processors
How would a CISC processor, a stack machine or a GPU do the job of your
block differently? (Look at the RISC-V vs Mano comparison in docs/ARCHITECTURE.md.)

Ans: A CISC processor may use a more complex control unit and different internal data paths to select memory or I/O data. A stack machine may pass data through its stack instead of using general-purpose registers. A GPU uses many parallel processing lanes and can have different memory access paths. However, all of them need some mechanism to select the correct data source.

## U6 Memory and I/O
How does your block take part in a memory access or an I/O transfer? If it
does not, explain which neighbouring block does and how data reaches it.

Ans: My block is part of the read-data path. It receives data from ROM, RAM and the I/O interface and forwards the selected source to the processor. The address decoder and control signals decide which source should be selected. The selector itself does not store data; it only passes the selected data.

## E1 Instruction trace: SRA
Trace one **SRA** instruction through the whole RC-V processor,
block by block (use docs/ARCHITECTURE.md and the simulator's --trace output).
List the blocks it passes through and the value on the main signals.

Ans: The SRA (Shift Right Arithmetic) instruction is an R-type instruction. It performs an arithmetic right shift on the value in the source register by the shift amount specified in the second source register.

**Blocks involved:**

1. **Fetch:** P14 (PC) provides the address to P30 (ROM), which fetches the SRA instruction.
2. **Decode:** P17 extracts the instruction fields. P21 identifies the OP instruction class. P22/P23 generate the control word, and P24 selects/checks the control signals. P13 reads the source registers.
3. **Execute:** P26 selects the operands. P10 generates the ALU control, and P01–P08 perform the arithmetic right shift.
4. **Memory:** No data memory access is required because SRA is an arithmetic instruction, not a load or store.
5. **Write-back:** P25 selects the ALU result, and P11/P12 write the result into the destination register.
6. **Next PC:** P03, P16 and P15 select and update the next sequential PC.

**Main control signals:**
- Instruction class: OP
- Control word: 0x4000
- regwrite = 1
- memread = 0
- memwrite = 0
- wbsel = 00 (ALU result)
- P32 read selector: Not used for SRA.

## E2 Neighbour review
Review the pull requests of P31 (Address decoder (memory map)) and P33 (I/O read bus). Paste the links to your review
comments here.

Ans: ### E2 Neighbour review

**P31 – Address decoder (memory map):**

**P33 – I/O read bus:**

## E3 Where my block sits
In two or three sentences: which layer of the computer is your block in
(gates / components / datapath / control / instruction set / memory / I/O),
which blocks feed it and which blocks use its output?

Ans : My block belongs to the datapath and memory/I/O interface layer. It receives data from ROM, RAM and the I/O read bus, using select signals from the control/address-decoding logic. Its output is used by the processor's read-data path.

## E4 Syllabus map
Tick every syllabus topic your work touched (main units: Unit 2, Unit 6).

- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [ ] Flip-flops, registers, counters
- [x] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [ ] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA
