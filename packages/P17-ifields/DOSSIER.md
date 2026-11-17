# P17 Instruction Field Splitter — Dossier

## U1 Digital logic

The P17 block is a combinational bit-field splitter. It does not perform Boolean calculations and does not need logic gates or flip-flops. Each output is a direct slice of the 32-bit instruction input.

| Output | Instruction bits | Width | Expression |
|---|---:|---:|---|
| `opcode` | `[6:0]` | 7 | `instr[6:0]` |
| `rd` | `[11:7]` | 5 | `instr[11:7]` |
| `funct3` | `[14:12]` | 3 | `instr[14:12]` |
| `rs1` | `[19:15]` | 5 | `instr[19:15]` |
| `rs2` | `[24:20]` | 5 | `instr[24:20]` |
| `funct7` | `[31:25]` | 7 | `instr[31:25]` |
| `csr` | `[31:20]` | 12 | `instr[31:20]` |

For example, `funct3` is simply the three bits `instr[14:12]`. No simplification is required. The `csr` output intentionally overlaps the `rs2` and `funct7` ranges because the same instruction bits have different meanings in different instruction formats.

## U2 Digital components

The Digital circuit contains:
- One 32-bit input pin named `instr`.
- One 32-bit Splitter configured with output ranges `0-6, 7-11, 12-14, 15-19, 20-24, 25-31, 20-31`.
- Seven output pins: `opcode`, `rd`, `funct3`, `rs1`, `rs2`, `funct7`, and `csr`.

There are no adders, multiplexers, decoders, registers, or memory blocks in this circuit. The splitter's seven output groups are wired to the corresponding output pins. The `csr` output overlaps the `rs2` and `funct7` outputs intentionally.

## U3 Data representation

The following examples show how a 32-bit instruction is divided into fields.

| Instruction | Binary (grouped in 4-bit nibbles) | Unsigned decimal | Selected fields |
|---|---|---:|---|
| `0x00C58533` (`add x10,x11,x12`) | `0000 0000 1100 0101 1000 0101 0011 0011` | 12,944,691 | opcode=`0x33`, rd=10, funct3=0, rs1=11, rs2=12, funct7=`0x00` |
| `0x407302B3` (`sub x5,x6,x7`) | `0100 0000 0111 0011 0000 0010 1011 0011` | 1,081,279,155 | opcode=`0x33`, rd=5, funct3=0, rs1=6, rs2=7, funct7=`0x20` |
| `0xFFF00093` (`addi x1,x0,-1`) | `1111 1111 1111 0000 0000 0000 1001 0011` | 4,293,918,867 | opcode=`0x13`, rd=1, funct3=0, rs1=0, immediate=`0xFFF` |

The third instruction demonstrates why field extraction and immediate generation are different operations. The splitter returns the 12-bit immediate field `0xFFF`; the I-type immediate generator sign-extends it to the 32-bit value `0xFFFFFFFF`, which represents −1. The splitter itself does not sign-extend values.

Overflow cannot occur in this splitter because it only copies bits. Arithmetic overflow is handled elsewhere, such as in the ALU. When extracting `funct7`, a logical right shift is appropriate because the field is an unsigned bit pattern; an arithmetic shift could replicate the sign bit.

## U4 Computer organisation

The instruction field splitter works during the **decode stage**. The instruction is first fetched from instruction memory using the program counter. Its 32-bit value is then divided into fields so that the control unit, register file, and immediate generator can use the required parts.

The opcode is used to identify the instruction class. The `rd`, `rs1`, and `rs2` fields identify registers where applicable. The `funct3` and `funct7` fields provide additional operation information, and the 12-bit `csr` field is used by CSR instructions. The field positions are available for every instruction, although not every format uses every field.

## U5 Processors

- **CISC processor:** Many CISC instruction sets have variable-length instructions and more complex encodings. A decoder may first need to determine the instruction length and decode different formats, rather than relying on the same fixed field positions used by this 32-bit RISC-V block.
- **Stack machine:** A stack machine normally gets operands from the stack. Many of its instructions do not contain explicit `rs1`, `rs2`, and `rd` register fields, so its decoder would extract a different set of fields.
- **GPU:** A GPU also decodes instructions, but an instruction may be executed by many parallel threads. The decoded operation and register information are applied across the relevant execution lanes.

RISC-V's regular 32-bit instruction formats make this particular splitter simple: it can use fixed bit ranges.

## U6 Memory and I/O

The P17 splitter does not directly read or write memory and does not control I/O. Instruction fetch and instruction memory provide the instruction word to the decode logic. The splitter separates its fields. Other processor blocks handle data-memory operations: for example, the register numbers and immediate information help the datapath calculate addresses for loads and stores.

The P17 mini-disassembler program also uses the supplied library routines `rcv_read_hex`, `rcv_puts`, `rcv_putc`, `rcv_print_udec`, and `rcv_newline` to receive keyboard input and print text. Those routines communicate with the RC-V input and output devices; the splitter itself does not perform those transfers. This project does not implement DMA.

## E1 Instruction trace: SLTI

Example instruction: `slti t1, t0, 10` (machine code: `0x00A2A313`).

Before execution, `t0 = 5`.

| Cycle | PC | Instruction | Operation |
|---|---|---|---|
| 51 | `0x230` | `0x00500293` | First instruction of `li t0, 5` |
| 52 | `0x234` | `0x00000013` | Second word of expanded `li` |
| 53 | `0x238` | `0x00A2A313` | Executes SLTI and writes 1 to `t1` |
| 54 | `0x23C` | `0x00008067` | Returns from the program |

During decode, P17 extracts opcode `0x13`, destination register `x6`, source register `x5`, and immediate `10`. The control unit recognizes an immediate ALU instruction and selects signed comparison. The register file supplies 5, while the immediate generator supplies 10. The ALU evaluates `5 < 10` and produces 1. Write-back stores 1 in `t1` (`x6`). No data-memory access occurs, and the next instruction address is PC + 4.

The trace also includes startup and ABI-checking instructions; the SLTI instruction itself executes at PC `0x238`.

## E2 Neighbour Review

### Review Partner 1: P16 – Next-PC Decision Logic

**Review Status:** Pending – Pull request was not available at the time of review.

The P16 implementation could not be reviewed because its pull request was not available in the repository when the review was conducted. No review comments were submitted.

### Review Partner 2: P18 – Immediate Generator (I/S)

**Pull Request:** [P18 Submission #50](https://github.com/campus-sutra/rc-v/pull/50)

**Review Status:** Submitted – Comment

The P18 submission was reviewed by examining its Digital circuit (`P18.dig`), Verilog module (`p18_imm_is.v`), assembly program (`p18.s`), and documentation (`DOSSIER.md`).

Four inline review comments were submitted to provide technical clarifications and suggestions for improving the documentation.

**Review Comments:**

1. **CSR Address Clarification**

   Clarified that the CSR address is extracted directly from instruction bits `[31:20]` and is used separately by CSR logic, rather than being treated as a sign-extended immediate generated by P18.

   [View GitHub Review Comment](https://github.com/campus-sutra/rc-v/pull/50#discussion_r4552589753)

2. **Simulator Trace Evidence**

   Requested actual simulator `--trace` output, including the observed program counter, instruction encoding, and register write-back values, to support the SLTIU instruction trace.

   [View GitHub Review Comment](https://github.com/campus-sutra/rc-v/pull/50#discussion_r4552649389)

3. **RISC-V Compressed Instruction Clarification**

   Suggested clarifying that the 32-bit instruction statement applies to the base RV32I instruction set, while the optional compressed (C) extension supports 16-bit instructions.

   [View GitHub Review Comment](https://github.com/campus-sutra/rc-v/pull/50#discussion_r4552674975)

4. **Memory and I/O Responsibility Clarification**

   Suggested distinguishing P18's role in generating immediate offsets from the ALU's role in calculating effective addresses and the memory/peripheral blocks' role in handling accesses.

   [View GitHub Review Comment](https://github.com/campus-sutra/rc-v/pull/50#discussion_r4552678846)

**Overall Review:** The I-type and S-type immediate-generation logic appeared correct in the submitted Verilog implementation. The review focused on improving technical accuracy and documentation clarity.

## E3 Where my block sits

My block sits in the instruction decode part of the processor datapath. It receives the 32-bit instruction from instruction fetch and sends the extracted fields to the control unit, register file, immediate generator, and CSR-related logic. It is a combinational wiring component and does not store data.

## E4 Syllabus map

The following topics are directly touched by the P17 work:

- [ ] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (field splitting is combinational; this design does not use adders, decoders, encoders, or multiplexers)
- [ ] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM) — discussed as neighboring blocks, but not implemented by P17
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [x] Register organisation, stack, addressing modes — register fields and the program's stack/register preservation are discussed
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA — keyboard and terminal I/O are used through library routines; DMA is not implemented by P17
