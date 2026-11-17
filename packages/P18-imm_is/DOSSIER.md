# P18 Immediate generator I/S - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic
Give the truth table (or state table) of one part of your circuit and the
simplified Boolean expression you used. Which gates or flip-flops did you need?

Sign extension replicates the sign bit `instr[31]` across the upper 20 bits (`imm[31:12]`). For any upper output bit $y_k$ ($12 \le k \le 31$) with input sign bit $s = \text{instr}[31]$:

| $s = \text{instr}[31]$ | $y_k = \text{imm}[k]$ | Meaning |
| :---: | :---: | :--- |
| `0` | `0` | Non-negative 12-bit immediate (zero-filled upper bits) |
| `1` | `1` | Negative 12-bit 2's complement immediate (one-filled upper bits) |

Simplified Boolean expression for the extended upper bits:

$$
y_k = \text{instr}[31] \quad \text{for } 12 \le k \le 31
$$

Boolean bit-mapping for the lower 12 bits:

$$
\text{imm\_i}[k] = \text{instr}[20 + k] \quad \text{for } 0 \le k \le 11
$$

$$
\text{imm\_s}[k] = \begin{cases} \text{instr}[7 + k] & \text{for } 0 \le k \le 4 \\ \text{instr}[20 + k] & \text{for } 5 \le k \le 11 \end{cases}
$$

No logic gates or flip-flops are needed: P18 is a purely combinational wiring block built with bus splitters and sign-bit fan-out.

## U2 Digital components
Which building blocks (adders, multiplexers, decoders, registers, memory)
does your Digital circuit use, and how are they connected?

[P18.dig](P18.dig) uses only **Splitter** and labelled **Tunnel** components (no adders, multiplexers, registers, or memory):

1. **Field Extractor (`Splitter: 32 -> 20-31, 7-11, 25-31, 31-31`)**: Splits `instr[31:0]` into `imm_i[11:0]` (bits `[31:20]`), `imm_s[4:0]` (bits `[11:7]`), `imm_s[11:5]` (bits `[31:25]`), and `sign` (bit `31`), feeding labelled output tunnels.
2. **I-type Combiner (`Splitter: 12, 1*20 -> 32`)**: Connects `imm_i[11:0]` to bits `[11:0]` and fans out the `sign` tunnel across all 20 upper 1-bit inputs `[31:12]` to drive `imm_i`.
3. **S-type Combiner (`Splitter: 5, 7, 1*20 -> 32`)**: Connects `imm_s[4:0]` to `[4:0]`, `imm_s[11:5]` to `[11:5]`, and fans out `sign` across `[31:12]` to drive `imm_s`.

In the RC-V datapath (`shared/rtl/rcv_soc.v`), P18 and P19 feed `P20` (`p20_imm_select`), which selects the active 32-bit immediate for `P26` (`p26_opab_mux`) and `P02` (`p02_target_adder`).

## U3 Data representation
Pick three test vectors of your block and explain them in binary, hex and
decimal (signed where it matters). Where could overflow or sign extension go wrong?

1. **Positive immediate (`instr = 0x2987BF71`)**
   - Binary: `0010 1001 1000 0111 1011 1111 0111 0001` (`instr[31] = 0`)
   - `imm_i`: bits `[31:20] = 0010 1001 1000` (`0x298`) $\rightarrow$ `0x00000298` (`+664` signed)
   - `imm_s`: `[31:25] = 0010100`, `[11:7] = 11110` $\rightarrow$ `0010 1001 1110` (`0x29E`) $\rightarrow$ `0x0000029E` (`+670` signed)

2. **Negative immediate (`instr = 0xB38C86DB`)**
   - Binary: `1011 0011 1000 1100 1000 0110 1101 1011` (`instr[31] = 1`)
   - `imm_i`: bits `[31:20] = 1011 0011 1000` (`0xB38`) $\rightarrow$ `0xFFFFFB38` (`-1224` signed)
   - `imm_s`: `[31:25] = 1011001`, `[11:7] = 01101` $\rightarrow$ `1011 0010 1101` (`0xB2D`) $\rightarrow$ `0xFFFFFB2D` (`-1235` signed)

3. **Minimum negative 12-bit boundary (`instr = 0x80000000`)**
   - Binary: `1000 0000 0000 0000 0000 0000 0000 0000` (`instr[31] = 1`)
   - Both `imm_i` and `imm_s` extract `1000 0000 0000` (`0x800`) and sign-extend to `0xFFFFF800` (`-2048` signed, the minimum 12-bit 2's complement value $-2^{11} = -2048$).

**Where it could go wrong:**
- **Zero-extension instead of sign-extension:** Leaving upper bits `[31:12]` as `0` turns negative offsets (e.g., `-1` = `0xFFF`) into `+4095`, breaking negative pointer offsets (`sp` / frame offsets) and `SLTIU` comparisons.
- **Misordered S-type slices:** Concatenating `[11:7]` above `[31:25]` instead of `{instr[31:25], instr[11:7]}` scrambles store offsets.
- **Range overflow:** A 12-bit signed immediate can only represent $[-2048, +2047]$; larger offsets require `LUI` + `ADDI`.

## U4 Computer organisation
In which step of the instruction cycle (fetch, decode, execute, memory,
write-back, interrupt) does your block do its work? Which instructions need it?

P18 works in the **Decode** step of the single-cycle instruction cycle, in parallel with `P17` (field splitter), `P21`–`P24` (control decode), and `P13` (register file read).

- **Instructions using `imm_i`:** `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI`, loads (`LB`, `LH`, `LW`, `LBU`, `LHU`), and `JALR`.
  *(Note on CSR instructions: In `CSRRW`, `CSRRS`, and `CSRRC`, the 12-bit CSR address occupies instruction bits `[31:20]`, which physically matches the I-type immediate position. However, in the RC-V datapath (`shared/rtl/rcv_soc.v`), the CSR address is extracted as an unsigned 12-bit field directly by `P17` (`csr[11:0]`) and fed to `P37` (`u_csr`), rather than utilizing the sign-extended 32-bit `imm_i` output from `P18`.)*
- **Instructions using `imm_s`:** stores (`SB`, `SH`, `SW`).

## U5 Processors
How would a CISC processor, a stack machine or a GPU do the job of your
block differently? (Look at the RISC-V vs Mano comparison in docs/ARCHITECTURE.md.)

- **RISC-V vs Mano's Basic Computer:** Mano's 16-bit computer has only one fixed 12-bit memory-address field (`IR[11:0]`) and no general immediate ALU operands. RISC-V (in its base RV32I specification, as implemented in RC-V) uses fixed 32-bit instructions aligned to 4-byte boundaries and places the sign bit at `instr[31]` across all formats so P18/P19 can sign-extend in parallel with opcode decoding. (While standard RISC-V supports the optional compressed "C" extension with 16-bit instructions, RC-V exclusively uses uncompressed RV32I).
- **CISC (e.g., x86):** Variable-length instructions (1–15 bytes) place 8/16/32/64-bit immediates at opcode-dependent byte offsets, requiring sequential length decoding and byte-steering logic rather than fixed bit slices.
- **Stack machine:** Immediates are pushed onto the stack by separate push instructions (`BIPUSH`, `SIPUSH`), while ALU instructions operate implicitly on the top of the stack.
- **GPU (SIMT):** Scalar/uniform constants are often stored in constant memory or broadcast from a shared scalar unit across all threads in a warp to save instruction bandwidth.

## U6 Memory and I/O
How does your block take part in a memory access or an I/O transfer? If it
does not, explain which neighbouring block does and how data reaches it.

P18 generates the signed 32-bit byte offset for every load (`imm_i`) and store (`imm_s`) instruction. In the RC-V datapath, `P20` selects `imm_i` (`immsel = 0`) or `imm_s` (`immsel = 1`), `P26` routes it to ALU input `opb` (`bsel_imm = 1`), and `P01`/`P08` add it to base register `r1` (`opa`):

$$
\text{bus\_addr} = \text{Reg}[rs1] + \text{imm}
$$

The resulting `bus_addr` passes through `P34` (bus arbiter) to `P31` (address decoder), which selects the target device in the RC-V memory map (`docs/ARCHITECTURE.md`):
- `0x0000_0000 - 0x0000_FFFF` (64 KB): Boot ROM (`P30`)
- `0x0001_0000 - 0x0001_3FFF` (16 KB): Data RAM (`P29`)
- `0x0002_0000 - 0x0002_07FF` (2 KB): Memory-mapped I/O slots via `P33` (e.g., UART terminal `P41` at slot 0, keyboard `P42` at slot 1, GPIO `P43` at slot 2, timer `P46` at slot 3)

## E1 Instruction trace: SLTIU
Trace one **SLTIU** instruction through the whole RC-V processor,
block by block (use docs/ARCHITECTURE.md and the simulator's --trace output).
List the blocks it passes through and the value on the main signals.

Tracing `sltiu x5, x6, -1` (`0xFFF33293`, with `x6 = 0x00000005`) from `python3 -m rcv.progrun 18 ... --trace`:

```text
    51 00000230 00500313  x6=0x00000005
    52 00000234 00000013
    53 00000238 fff33293  x5=0x00000001
    54 0000023c 00008067
```

Block-by-block signal trace for cycle 53 (`pc = 0x00000238`, `instr = 0xFFF33293`):

1. **Fetch:**
   - `P14` (`u_pc`): outputs `pc = 0x00000238`.
   - `P30` (`u_rom`): outputs `instr = 0xFFF33293`.
   - `P03` (`u_pc4`): computes `pc4 = 0x0000023C`.
2. **Decode:**
   - `P17` (`u_fields`): `opcode = 7'b0010011` (`0x13`), `rd = 5'd5` (`x5`), `funct3 = 3'b011`, `rs1 = 5'd6` (`x6`).
   - `P21` (`u_class`): asserts `is_opimm = 1`.
   - `P22`/`P23` $\rightarrow$ `P24` (`u_ctrl`): outputs `ctrl = 16'h5000` (`c_regwrite = 1`, `c_asel_pc = 0`, `c_bsel_imm = 1`, `c_a_zero = 0`, `c_memread = 0`, `c_memwrite = 0`, `c_wbsel = 2'd0`, `c_immsel = 3'd0`, `c_branch = 0`, `c_jal = 0`, `c_jalr = 0`, `c_csr = 0`).
   - `P18` (`u_imm_is`): extracts `instr[31:20] = 0xFFF`, sign-extends bit 31 $\rightarrow$ `imm_i = 0xFFFFFFFF`.
   - `P20` (`u_imm`): `c_immsel = 0` selects `imm = 0xFFFFFFFF`.
   - `P13` (`u_rf_rs1`): reads `rs1 = 6` $\rightarrow$ `r1 = 0x00000005`.
3. **Execute:**
   - `P26` (`u_opab`): `c_bsel_imm = 1` routes `opa = 0x00000005`, `opb = 0xFFFFFFFF`.
   - `P10` (`u_aluctl`): `is_opimm = 1, funct3 = 3'b011` $\rightarrow$ `aluop = 4'd9` (`SLTU`).
   - `P07` (`u_slt`): compares `opa` and `opb` unsigned (`5 < 4294967295`) $\rightarrow$ `ltu = 1`.
   - `P08` (`u_alu`): `aluop = 9` selects `alu_y = 0x00000001`.
4. **Memory (idle):**
   - `c_memread = 0`, `c_memwrite = 0`: `P34`/`P31`/`P29` perform no memory read or write.
5. **Write-back & Next PC:**
   - `P25` (`u_wb`): `c_wbsel = 0` selects `wd = alu_y = 0x00000001`.
   - `P11`/`P12`: `rf_write = 1`, `rd = 5` writes `0x00000001` into `x5` on the rising clock edge.
   - `P16`/`P15`: no branch/jump/trap, so `pc` updates to `pc4 = 0x0000023C`.

## E2 Neighbour review
Review the pull requests of P17 (Instruction field splitter) and P19 (Immediate generator B/J/U). Paste the links to your review
comments here.

- **P17 (Instruction field splitter)** — owner `@Shivam808119` (Join issue: https://github.com/campus-sutra/rc-v/issues/23): no pull request has been opened on `campus-sutra/rc-v` yet. Once P17 opens a PR, I will verify that its `opcode[6:0]`, `rd[11:7]`, `funct3[14:12]`, `rs1[19:15]`, `rs2[24:20]`, `funct7[31:25]`, and `csr[31:20]` bit ranges match `P18`'s overlapping `instr[31:20]` and `instr[11:7]` slices and link my review comment here.
- **P19 (Immediate generator B/J/U)** — owner `@ashu751867-collab` (Join issue: https://github.com/campus-sutra/rc-v/issues/38): no pull request has been opened on `campus-sutra/rc-v` yet. Once P19 opens a PR, I will review its sign-extension and bit-scrambling for `imm_b`, `imm_j`, and `imm_u` (which share `P20` with `P18`) and link my review comment here.

## E3 Where my block sits
In two or three sentences: which layer of the computer is your block in
(gates / components / datapath / control / instruction set / memory / I/O),
which blocks feed it and which blocks use its output?

P18 sits in the **decode stage of the datapath** layer. It is fed directly by the 32-bit `instr` bus from Boot ROM `P30` (`u_rom`). Its outputs `imm_i` and `imm_s` feed the immediate selector multiplexer `P20` (`u_imm`), which supplies the active 32-bit immediate to operand selector `P26` (`u_opab`) for the ALU and address calculation, and to `P02` (`u_target`).

## E4 Syllabus map
Tick every syllabus topic your work touched (main units: Unit 3, Unit 4).

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
- [ ] I/O interface, programmed / interrupt-driven I/O, DMA
