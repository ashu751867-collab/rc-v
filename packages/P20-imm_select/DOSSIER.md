# P20 Immediate Selector – Dossier

## U1 Digital logic
My circuit uses a multiplexer to select one of five 32-bit immediate inputs.

| immsel | Output |
|---|---|
| 000 | imm_i |
| 001 | imm_s |
| 010 | imm_b |
| 011 | imm_u |
| 100 | imm_j |
| 101–111 | 0 |

Boolean expression:

`imm = (immsel=0 AND imm_i) OR (immsel=1 AND imm_s) OR (immsel=2 AND imm_b) OR (immsel=3 AND imm_u) OR (immsel=4 AND imm_j)`

I used a multiplexer; no flip-flops are needed.

## U2 Digital components
I used an 8-to-1 multiplexer. Five inputs are connected to the immediate values, three inputs to zero, and `immsel` controls the selection.

## U3 Data representation
1. `0000007F` = 127 decimal (I-type).
2. `FFFFFFF0` = -16 decimal (S-type, signed).
3. `00000800` = 2048 decimal (J-type).

Overflow is not caused by selection, but incorrect truncation or sign extension can cause errors.

## U4 Computer organisation
P20 works after instruction decoding. It selects the immediate needed by instructions such as ORI, ADDI, loads, stores, branches and jumps.

## U5 Processors
RISC-V uses a separate immediate selector. CISC may use more complex decoding, stack machines use stack-based operands, and GPUs repeat similar selection logic across processing units.

## U6 Memory and I/O
P20 does not directly access memory or I/O. For load and store instructions, it provides the immediate offset used to calculate the memory address.

## E1 Instruction trace: ORI
ORI uses an I-type immediate. The decoder identifies ORI, sets `immsel = 000`, and P20 selects `imm_i`. The ALU performs bitwise OR, and the result is written to the destination register.

## E2 Neighbour review
Review the pull requests of P19 (Immediate generator B/J/U) and P21 (Opcode class decoder). Paste the links to your review
comments here.
- P19 review comment: not done yet
- P21 review comment: not done yet

## E3 Where my block sits
P20 is a combinational datapath component. It receives immediate values and a control signal, then sends the selected immediate to the execution datapath.

## E4 Syllabus map
- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [ ] Flip-flops, registers, counters
- [x] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [x] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA