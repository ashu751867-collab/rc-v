# P09 Branch comparator - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic
For a single-bit equality check ($eq_i$) between bit $a_i$ and bit $b_i$, the output is `1` when both bits match:

| $a_i$ | $b_i$ | $eq_i$ |
| :---: | :---: | :---: |
| 0 | 0 | 1 |
| 0 | 1 | 0 |
| 1 | 0 | 0 |
| 1 | 1 | 1 |

- **Simplified Boolean expression (1-bit equality):** $eq_i = \overline{a_i \oplus b_i} = a_i b_i + \overline{a_i}\overline{b_i}$
- **4-bit equality:** $eq = eq_3 \cdot eq_2 \cdot eq_1 \cdot eq_0$
- **Gates/Flip-flops used:** Purely combinational logic using `XNOR`, `NOT`, `AND`, and `OR` gates (zero flip-flops).

## U2 Digital components
- **Splitters:** Two 4-bit splitters break inputs `a[3:0]` and `b[3:0]` into individual bit lines (`a0..a3`, `b0..b3`).
- **Equality & Magnitude comparators:** Bitwise `XNOR` gates feed a 4-input `AND` gate to produce `eq`, while cascading `AND`/`OR`/`NOT` logic computes unsigned less-than (`ltu`) and signed less-than (`lt`, by inverting the MSB sign bits $a_3$ and $b_3$).
- **Multiplexer (8-to-1):** The 3-bit `funct3` input acts as the selector line for an 8-input `Multiplexer` wired to `eq` (`0`), `~eq` (`1`), `0` (`2`, `3`), `lt` (`4`), `~lt` (`5`), `ltu` (`6`), and `~ltu` (`7`), producing the 1-bit `take` output.

## U3 Data representation
1. **Vector 1 (`a = -5`, `b = 3`, `funct3 = 4` / `BLT`):**
   - **Binary (4-bit):** `a = 1011`, `b = 0011` | **Hex:** `a = 0xB`, `b = 0x3`
   - **Result:** Signed `-5 < +3` is true, so `take = 1`. (Under unsigned comparison `BLTU`, `11 < 3` would be `0`.)
2. **Vector 2 (`a = -1`, `b = 1`, `funct3 = 6` / `BLTU`):**
   - **Binary (4-bit):** `a = 1111`, `b = 0001` | **Hex:** `a = 0xF`, `b = 0x1`
   - **Result:** In unsigned representation `0xF` is `15` and `0x1` is `1`. Since `15 < 1` is false, `take = 0`.
3. **Vector 3 (`a = -8`, `b = -8`, `funct3 = 0` / `BEQ`):**
   - **Binary (4-bit):** `a = 1000`, `b = 1000` | **Hex:** `a = 0x8`, `b = 0x8`
   - **Result:** All bits match (`eq = 1`), so `take = 1`.
- **Where overflow or sign extension can go wrong:** If signed comparison were implemented via subtraction (`a - b`) without checking overflow, `(-8) - (+7)` in 4-bit two's complement wraps around to `+1` (positive), falsely reporting `-8 > +7`. Also, failing to sign-extend B-type immediate offsets or comparing zero-extended values in `BLT`/`BGE` corrupts negative number comparisons.

## U4 Computer organisation
- **Instruction cycle stage:** **Execute (EX)** stage (combinational evaluation during the cycle).
- **Instructions that need it:** All six RISC-V B-type conditional branch instructions: `BEQ` (`funct3 = 000`), `BNE` (`001`), `BLT` (`100`), `BGE` (`101`), `BLTU` (`110`), and `BGEU` (`111`).

## U5 Processors
- **CISC processor (e.g., Mano's basic computer / x86):** Sets condition code flags (`Z`, `N`, `C`, `V`) in a status register during an ALU `CMP` or `SUB` instruction, and a subsequent conditional jump (`JZ`, `JL`, `JB`) reads those stored flags rather than comparing two registers directly in one instruction.
- **Stack machine:** Pops the top two operands off the evaluation stack, performs a comparison that pushes a boolean (`0` or `1`) back onto the stack, and then executes a conditional branch instruction that pops that single flag.
- **GPU (SIMT):** Executes branches across a warp of 32 threads simultaneously using per-thread active masks and divergence stacks; if threads disagree on `take`, both paths are serialized with inactive threads masked off until reconvergence.

## U6 Memory and I/O
The branch comparator does **not** directly participate in data memory loads/stores or memory-mapped I/O transfers. Instead, its `take` output feeds the **Control Unit / Next-PC Mux**, which selects whether the **Program Counter (`PC`)** fetches the next instruction from `PC + 4` or from the branch target `PC + imm_B` via **Instruction Memory**; actual data memory and I/O transfers are handled by the ALU (`rs1 + imm`) and Data Memory / Bus interface during `LW`/`SW`.

## E1 Instruction trace: BLTU
Tracing `bltu x5, x6, +12` (encoded with `opcode = 1100011`, `funct3 = 110`, `rs1 = x5`, `rs2 = x6`, `imm = 12`) at `PC = 0x00000010` with `x5 = 0x00000004` and `x6 = 0xFFFFFFFE`:
1. **Program Counter & Instruction Memory (IF):** `PC` outputs `0x00000010` to Instruction Memory, which fetches the 32-bit B-type machine word; simultaneously the PC incrementer computes `PC + 4 = 0x00000014`.
2. **Decoder & Immediate Generator (ID):** Extracts `opcode = 7'b1100011` (branch), `funct3 = 3'b110` (`BLTU`), `rs1 = 5`, `rs2 = 6`, and reconstructs the sign-extended B-immediate `imm_B = 0x0000000C` (`+12`).
3. **Register File (ID):** Outputs `rs1_data (a) = 0x00000004` and `rs2_data (b) = 0xFFFFFFFE`.
4. **Branch Comparator (`p09_branch_cmp`, EX):** Receives `a = 0x00000004`, `b = 0xFFFFFFFE`, and `funct3 = 3'b110`. Unsigned comparison evaluates `4 < 4294967294` as true, asserting `take = 1` (whereas signed `lt` is `0`).
5. **Branch Target Adder & Control/PC Mux (EX/IF):** Branch adder computes `0x00000010 + 0x0000000C = 0x0000001C`. Because `Branch = 1` and `take = 1`, the Next-PC Mux selects `0x0000001C` instead of `0x00000014` (`RegWrite = 0`, `MemWrite = 0`).

## E2 Neighbour review
- **P08 (ALU result selector):** https://github.com/campus-sutra/rc-v/pulls?q=is%3Apr+P08 (Verified that the 8-to-1 result multiplexer maps `alu_op` cleanly to arithmetic, shift, logic, and SLT outputs without latches.)
- **P10 (ALU control):** https://github.com/campus-sutra/rc-v/pulls?q=is%3Apr+P10 (Verified that `ALUOp`, `funct3`, and `funct7[5]` decode R-type/I-type operations and force `ADD` for load/store address calculation.)

## E3 Where my block sits
My block sits in the **datapath / control boundary** of the processor (built from combinational **gates and components**). It is fed by the **Register File** (`rs1` and `rs2` 32-bit operand values) and the **Instruction Decoder** (`funct3`), and its 1-bit `take` output feeds the **Control Unit / Next-PC Multiplexer** to decide whether to branch to `PC + imm_B` or advance to `PC + 4`.

## E4 Syllabus map
Tick every syllabus topic your work touched (main units: Unit 1, Unit 3, Unit 4).

- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [ ] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
-
