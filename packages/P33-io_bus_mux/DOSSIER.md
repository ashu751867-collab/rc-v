# P33 I/O read bus - dossier

## U1 Digital logic
The circuit is a 4-to-1 multiplexer with a 2-bit select input. For each output bit, the selected device bit is
`rdata[i] = d0[i]·¬s1·¬s0 + d1[i]·¬s1·s0 + d2[i]·s1·¬s0 + d3[i]·s1·s0`.
The four select cases are 00, 01, 10 and 11, choosing device slots 0, 1, 2 and 3 respectively. The implementation uses a multiplexer rather than separate gates or flip-flops; it is combinational.

## U2 Digital components
The 16-bit `dev_flat` input is split into four 4-bit groups. Those groups connect to the four data inputs of a 4-bit-wide, 4-to-1 Multiplexer. The 2-bit `dev` input drives its selector, and the multiplexer output connects to `rdata`. No register or clock is required.

## U3 Data representation
Three example vectors from the public Digital test table are:
- `dev_flat=45962` = `0xB38A` = `1011 0011 1000 1010₂`, `dev=1`; the selected slot is bits 7..4, `1000₂`, so `rdata=8`.
- `dev_flat=32768` = `0x8000` = `1000 0000 0000 0000₂`, `dev=0`; the selected low nibble is `0000₂`, so `rdata=0`.
- `dev_flat=47776` = `0xBAA0` = `1011 1010 1010 0000₂`, `dev=2`; the selected nibble is `1010₂`, so `rdata=10`.
The values are unsigned bit patterns. There is no arithmetic overflow or sign extension: the circuit selects bits without changing them.

## U4 Computer organisation
P33 works during the memory-access part of the single-cycle instruction path when an I/O-mapped load is selected. The address decoder P31 selects the device, and the device's register data is routed through P33 and then the memory read selector P32, load extender P28 and write-back selector P25. Ordinary load instructions such as `LW`, `LB` and `LBU` can use this path.

## U5 Processors
A CISC processor could provide dedicated I/O instructions or a more complex I/O controller instead of using memory-mapped loads. A stack machine could select the device and push its data onto the stack rather than naming a destination register. A GPU would typically handle many parallel data lanes, while this block selects one device word for the scalar CPU datapath.

## U6 Memory and I/O
P33 is the I/O read-data multiplexer. The 32 device slots each provide a 32-bit read-data word; `dev` selects one of those words from the packed `dev_flat` bus. In the complete SoC, P31 decodes the address and selects a device, while P33 routes the selected device's data onward to P32 for the CPU load path.

## E1 Instruction trace: OR
For an `OR rd, rs1, rs2` instruction, P14 supplies the PC and P30 fetches the instruction. P17 separates opcode, register numbers and function bits; P21 identifies the OP class and P22/P23 produce the control word, checked by P24. P13 reads `rs1` and `rs2`; P26 selects the operands. P10 selects the OR ALU operation, and the logic unit P04 computes `rs1_value OR rs2_value` through the ALU selection block P08 (with P01/P05/P06/P07 providing the other ALU functions). P15 selects the sequential next PC using P03 and P16. Since OR is an arithmetic/logical register instruction, it does not access P33, P32, RAM or I/O. P25 selects the ALU result, and P11/P12 write it to `rd`.

## E2 Neighbour review
The assigned review partners are P32 (Memory read selector) and P34 (Bus arbiter (CPU vs DMA)). I have not submitted review comments yet, so I cannot provide genuine review URLs. After reviewing each partner's pull request, paste the actual GitHub review-comment links here:
- P32 review: [add your review-comment URL]
- P34 review: [add your review-comment URL]

## E3 Where my block sits
P33 is in the I/O datapath at the component level. Its inputs are the packed read-data outputs of the device slots and the selected device number; P31's address decoding determines which device is selected. P33's 32-bit output feeds P32, which selects among ROM, RAM and I/O data for the CPU load path.

## E4 Syllabus map
- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [ ] Flip-flops, registers, counters
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
