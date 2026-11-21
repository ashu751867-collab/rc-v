# P66 Reset controller - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic
Give the truth table (or state table) of one part of your circuit and the
simplified Boolean expression you used. Which gates or flip-flops did you need?

### U1 Digital logic

My circuit uses a 3-bit counter to control the reset signal.

The counter starts from 4 and decreases by 1 on every rising edge of the clock. When the counter reaches 0, the reset signal becomes LOW.

**Truth Table:**

| Q2 | Q1 | Q0 | rst |
|---|---|---|---|
| 0 | 0 | 0 | 0 |
| 0 | 0 | 1 | 1 |
| 0 | 1 | 0 | 1 |
| 0 | 1 | 1 | 1 |
| 1 | 0 | 0 | 1 |

**Boolean Expression:**

rst = Q2 + Q1 + Q0

Here, + represents the OR operation.

The circuit uses OR gates and flip-flops to store the counter states.

## U2 Digital components
Which building blocks (adders, multiplexers, decoders, registers, memory)
does your Digital circuit use, and how are they connected?
### U2 Digital components

My digital circuit uses a 3-bit counter made using flip-flops. These flip-flops store the current counter value.

It also uses logic gates to decrease the counter value by 1 on every rising edge of the clock.

When the button is pressed, the counter loads the value 4. The reset output depends on whether the counter value is zero or not.

The main components used are flip-flops, a decrementing circuit, a multiplexer-like selection logic and OR gates.

## U3 Data representation
Pick three test vectors of your block and explain them in binary, hex and
decimal (signed where it matters). Where could overflow or sign extension go wrong?

### U3 Data representation

My circuit uses a 3-bit counter to represent numbers.

Three test values are:

| Decimal | Binary | Hexadecimal |
|---|---|---|
| 4 | 100 | 0x4 |
| 2 | 010 | 0x2 |
| 1 | 001 | 0x1 |

The counter uses unsigned numbers, so it can represent values from 0 to 7.

Overflow can happen if the counter goes beyond its 3-bit range. Sign extension can also cause problems if an unsigned value is treated as a signed number.

Therefore, it is important to use the correct bit size and number representation.

## U4 Computer organisation
In which step of the instruction cycle (fetch, decode, execute, memory,
write-back, interrupt) does your block do its work? Which instructions need it?
### U4 Computer organisation

My reset controller works before the normal instruction cycle starts.

It keeps the processor in the reset state for 4 clock cycles after power-on or when the reset button is pressed.

After 4 clock cycles, it releases the reset signal and allows the processor to start fetching and executing instructions.

It is not used by any particular instruction. It helps the whole processor start working correctly.


## U5 Processors
How would a CISC processor, a stack machine or a GPU do the job of your
block differently? (Look at the RISC-V vs Mano comparison in docs/ARCHITECTURE.md.)

### U5 Processors

A reset controller is important for different types of processors.

**1. CISC Processor:** It needs a reset controller to initialise the processor before executing complex instructions.

**2. Stack Machine:** It needs a reset signal to initialise its registers and stack before starting operations.

**3. GPU:** A GPU has many processing units, so its reset controller may need to reset multiple units at the same time.

The main purpose of the reset controller remains the same: to make sure the processor starts working in a proper condition.

## U6 Memory and I/O
How does your block take part in a memory access or an I/O transfer? If it
does not, explain which neighbouring block does and how data reaches it.


### U6 Memory and I/O

The P66 Reset Controller does not directly take part in memory access or I/O data transfer. Its main job is to provide a reset signal to initialise the processor.

Memory and I/O operations are handled by their respective blocks. The reset controller helps ensure that the processor starts in a proper state before these operations begin.

## E1 Instruction trace: ADD
Trace one **ADD** instruction through the whole RC-V processor,
block by block (use docs/ARCHITECTURE.md and the simulator's --trace output).
List the blocks it passes through and the value on the main signals.

### E1 Instruction trace: ADD

An ADD instruction passes through the following blocks in the RC-V processor:

1. **Fetch:** P14 (PC) provides the instruction address and P30 (ROM) fetches the instruction.
2. **Decode:** P17 extracts the instruction fields. P21 identifies it as an OP instruction. P22/P23 generate the control word, and P24 selects the control. P13 reads the source registers.
3. **Execute:** P26 selects the operands, P10 controls the ALU, and P01–P08 perform the addition.
4. **Memory:** ADD does not require a data memory read or write.
5. **Write-back:** P25 selects the ALU result, and the register file (P11/P12/P13) writes it into the destination register.
6. **Next PC:** P03 calculates PC + 4, P16 selects the next address, and P15 updates the PC.

For an ADD instruction, the control word is **0x4000**. The `regwrite` signal is 1, `memread` and `memwrite` are 0, and `wbsel` is 00 because the ALU result is written back.


## E2 Neighbour review
Review the pull requests of P65 (Complement unit (r and r-1 complements)) and P49 (Performance counters). Paste the links to your review
comments here.



## E3 Where my block sits
In two or three sentences: which layer of the computer is your block in
(gates / components / datapath / control / instruction set / memory / I/O),
which blocks feed it and which blocks use its output?


### E3 Where my block sits

My block, P66 Reset Controller, belongs to the control layer of the computer. It receives the clock signal (`clk`) and reset button input (`btn`), and produces the reset signal (`rst`). This signal is used by blocks such as the PC register (P14), register file storage (P12), CSR file (P37), cache tags (P35), and I/O devices to initialise their state.

## E4 Syllabus map
Tick every syllabus topic your work touched (main units: Unit 1, Unit 4).

- [ ✓] Logic gates, Boolean algebra, K-maps
- [ ✓] Combinational circuits (adders, decoders, encoders, multiplexers)
- [ ✓] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [ ✓] Number systems, complements, signed arithmetic
- [ ✓] Bus organisation, instruction codes and formats
- [ ] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [✓ ] Register organisation, stack, addressing modes
- [ ✓] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [ ✓] I/O interface, programmed / interrupt-driven I/O, DMA
