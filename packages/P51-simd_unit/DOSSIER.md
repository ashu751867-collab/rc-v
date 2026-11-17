# P51 Four-lane vector unit (mini GPU) - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic
Give the truth table (or state table) of one part of your circuit and the
simplified Boolean expression you used. Which gates or flip-flops did you need?

The core logic of each 4-bit lane is an unsigned magnitude comparator that determines whether $a > b$ to drive the maximum-selection multiplexer. 

For two 4-bit unsigned inputs $A = [a_3, a_2, a_1, a_0]$ and $B = [b_3, b_2, b_1, b_0]$, equality at each bit position $k$ is given by an XNOR gate:

$$
e_k = \overline{a_k \oplus b_k} = a_k b_k + \overline{a_k} \, \overline{b_k}
$$

The single-bit greater-than condition is:

$$
g_k = a_k \cdot \overline{b_k}
$$

Truth table for a 1-bit comparator cell:

| $a_k$ | $b_k$ | $g_k = a_k \cdot \overline{b_k}$ ($a_k > b_k$) | $e_k = \overline{a_k \oplus b_k}$ ($a_k = b_k$) |
| :---: | :---: | :---: | :---: |
| `0` | `0` | `0` | `1` |
| `0` | `1` | `0` | `0` |
| `1` | `0` | `1` | `0` |
| `1` | `1` | `0` | `1` |

Using priority expansion from the most significant bit (MSB) to the least significant bit (LSB), the simplified Boolean expression for 4-bit unsigned greater-than comparison is:

$$
(A > B) = a_3 \overline{b_3} + e_3 (a_2 \overline{b_2}) + e_3 e_2 (a_1 \overline{b_1}) + e_3 e_2 e_1 (a_0 \overline{b_0})
$$

Gates needed: AND gates, OR gates, NOT gates (inverters), and XNOR gates. In `P51.dig`, this function is encapsulated in the built-in 4-bit `Comparator` component. In the Verilog module (`p51_simd_unit.v`), D-flip-flops are used for the registered operands `a_reg` and `b_reg` clocked on `clk` with synchronous reset `rst`.

## U2 Digital components
Which building blocks (adders, multiplexers, decoders, registers, memory)
does your Digital circuit use, and how are they connected?

`P51.dig` implements a 2-lane 4-bit SIMD processing block using the following standard digital components:

1. **Splitters (Input Bus Demultiplexing):** Two Splitters split the 8-bit inputs `a[7:0]` and `b[7:0]` into two independent 4-bit lanes (`lane 0 = bits 3..0` and `lane 1 = bits 7..4`).
2. **Adders (`Add`):** Two 4-bit binary adders compute the per-lane addition:
   - Lane 0 Adder adds `a[3:0]` and `b[3:0]` with carry-in $c_{in} = 0$ (tied to Ground).
   - Lane 1 Adder adds `a[7:4]` and `b[7:4]` with carry-in $c_{in} = 0$ (tied to Ground).
   - Crucially, carry-out from Lane 0 is discarded rather than propagated into Lane 1. This prevents inter-lane overflow and ensures strict SIMD lane isolation.
3. **Comparators (`Comparator`):** Two 4-bit magnitude comparators evaluate the unsigned condition $(a > b)$ for Lane 0 and Lane 1.
4. **Multiplexers (`Multiplexer`):** Two 4-bit 2-to-1 multiplexers select the lane maximum:
   - Input 0 is connected to $b$, input 1 is connected to $a$.
   - The select line is driven by the comparator's greater-than output ($a > b$).
   - When $a > b$, input 1 ($a$) is chosen; otherwise input 0 ($b$) is chosen.
5. **Splitters (Output Bus Aggregation):** Two Splitters (combining `4,4` into `8` bits) merge the lane sums into the 8-bit `sum` output, and the lane maximums into the 8-bit `max` output.

In the full 32-bit SoC architecture, P51 connects to the memory-mapped I/O bus at slot 9 (`0x00020240`), where CPU bus address decoders (`P31`) and multiplexers (`P33`) steer words between the CPU datapath and the 4-lane SIMD registers.

## U3 Data representation
Pick three test vectors of your block and explain them in binary, hex and
decimal (signed where it matters). Where could overflow or sign extension go wrong?

1. **Standard addition and maximum without lane overflow (`a = 18 = 0x12, b = 60 = 0x3C`):**
   - In binary: $a = \texttt{0001 0010}_2$ (Lane 1 = `0001` = 1, Lane 0 = `0010` = 2).
   - In binary: $b = \texttt{0011 1100}_2$ (Lane 1 = `0011` = 3, Lane 0 = `1100` = 12).
   - Lane 0 sum: $2 + 12 = 14 = \texttt{1110}_2 = \texttt{0xE}$.
   - Lane 1 sum: $1 + 3 = 4 = \texttt{0100}_2 = \texttt{0x4}$.
   - Result `sum` = $\texttt{0100 1110}_2 = \texttt{0x4E} = 78$.
   - Lane 0 max: $\max(2, 12) = 12 = \texttt{0xC}$.
   - Lane 1 max: $\max(1, 3) = 3 = \texttt{0x3}$.
   - Result `max` = $\texttt{0011 1100}_2 = \texttt{0x3C} = 60$.

2. **Wrap-around modular addition on lane boundary (`a = 109 = 0x6D, b = 255 = 0xFF`):**
   - $a$: Lane 1 = $6$ (`0110`), Lane 0 = $13$ (`1101`).
   - $b$: Lane 1 = $15$ (`1111`), Lane 0 = $15$ (`1111`).
   - Lane 0 sum: $13 + 15 = 28$. Modulo 16 wrap-around: $28 - 16 = 12 = \texttt{0xC} = \texttt{1100}_2$. The carry bit (16) is discarded.
   - Lane 1 sum: $6 + 15 = 21$. Modulo 16 wrap-around: $21 - 16 = 5 = \texttt{0x5} = \texttt{0101}_2$.
   - Result `sum` = $\texttt{0101 1100}_2 = \texttt{0x5C} = 92$.
   - Result `max` = $\texttt{1111 1111}_2 = \texttt{0xFF} = 255$.

3. **Unsigned vs signed comparison boundary (`a = 0xC1 = 193, b = 0x25 = 37`):**
   - $a$: Lane 1 = `1100` ($12$ unsigned), Lane 0 = `0001` ($1$ unsigned).
   - $b$: Lane 1 = `0010` ($2$ unsigned), Lane 0 = `0101` ($5$ unsigned).
   - In unsigned comparison: in Lane 1, $12 > 2$, so $\max(12, 2) = 12$ (`0xC`).
   - In Lane 0, $1 < 5$, so $\max(1, 5) = 5$ (`0x5`).
   - Expected unsigned `max` = $\texttt{0xC5} = 197$.

**Where overflow or sign extension could go wrong:**
- **Signed vs. Unsigned Interpretation:** Image pixel values ($0..255$, or $0..15$ in 4-bit) are strictly unsigned. If the comparator treats values with MSB=1 as negative 2's complement numbers (e.g., treating `1100` as $-4$ instead of $+12$), then $-4 < 2$, causing the comparator to incorrectly output $2$ instead of $12$.
- **Carry bleed-over between lanes:** In a standard 8-bit ripple adder, an overflow in Lane 0 would propagate into the carry-in of Lane 1, corrupting adjacent pixel values. SIMD adders must strictly truncate carry-outs to maintain lane independence.

## U4 Computer organisation
In which step of the instruction cycle (fetch, decode, execute, memory,
write-back, interrupt) does your block do its work? Which instructions need it?

P51 is an accelerated coprocessor mapped as an I/O device at slot 9. It does its work during the **Memory stage** of the CPU's instruction cycle:

1. **Store Instructions (`SW rs2, offset(rs1)`):**
   - When the program writes to SIMD_A (`0x00020240`) or SIMD_B (`0x00020244`), the store data (`wdata`) from `rs2` is transferred over the system bus during the **Memory** stage. On the rising edge of `clk`, P51 latches the word into `a_reg` or `b_reg`.
2. **Load Instructions (`LW rd, offset(rs1)`):**
   - When reading results from SIMD_SUM (`0x00020248`), SIMD_MAX (`0x0002024C`), or SIMD_SUB (`0x00020250`), P51 combinatorially calculates the four 8-bit lane operations and drives `rdata` onto the I/O bus during the **Memory** stage. During the subsequent **Write-back** stage, the CPU writes this result into destination register `rd`.

Instructions that use P51: standard RISC-V load and store instructions (`LW`, `SW`) directed to the memory-mapped addresses `0x00020240 - 0x0002027C`.

## U5 Processors
How would a CISC processor, a stack machine or a GPU do the job of your
block differently? (Look at the RISC-V vs Mano comparison in docs/ARCHITECTURE.md.)

- **CISC Processors (e.g., x86 with MMX/SSE/AVX):** CISC architectures provide dedicated SIMD instruction set extensions that operate directly on wide vector registers (such as 64-bit `MMX` or 128-bit `XMM` registers). Instead of performing memory-mapped bus transfers, CISC programs execute dedicated assembly instructions like `PADDB` (packed add byte) and `PMAXUB` (packed maximum unsigned byte) within the CPU's execution pipeline in a single cycle.
- **Stack Machine:** A stack machine lacks general-purpose registers and memory-mapped bus interfaces. Operands must be pushed onto the evaluation stack. Performing lane-wise SIMD operations would require either dedicated vector push/pop instructions or costly sequential decomposition, duplicating and shuffling elements on the top of the stack.
- **GPU (SIMT Architecture):** Modern GPUs execute parallel operations across thousands of scalar threads grouped into warps (or wavefronts). Instead of packing multiple pixels into one 32-bit register and calculating lane sub-words with bitwise masking, each thread executes a standard scalar instruction on its own individual pixel data in parallel across massive arrays of ALUs.
- **RC-V Architecture:** RC-V utilizes an elegant embedded SoC approach: rather than adding complex vector instructions and multi-read register files to the scalar CPU core, vector acceleration is provided via a memory-mapped peripheral, keeping the processor core simple and modular.

## U6 Memory and I/O
How does your block take part in a memory access or an I/O transfer? If it
does not, explain which neighbouring block does and how data reaches it.

P51 connects directly to the RC-V memory-mapped I/O (MMIO) bus architecture:

1. **Address Decoding:** When the CPU executes a load or store instruction, the base register and immediate offset are summed by ALU adder `P01`/`P08` to form `bus_addr`. The memory bus arbiter `P34` passes this address to the address decoder `P31` (`addr_decode`).
2. **Device Selection:** `P31` identifies addresses in the range `0x00020240 - 0x0002027F` (Slot 9) and asserts `sel = 1` for P51. The lower address bits `addr[5:2]` determine register index `ridx[3:0]`.
3. **Data Transfer:**
   - On a store (`we = 1`), `wdata` from the CPU datapath is written to `a_reg` (`ridx = 0`) or `b_reg` (`ridx = 1`) on the rising clock edge.
   - On a read (`re = 1`), P51 outputs the requested computation (`rdata`) onto the slot 9 bus lines.
4. **Read Multiplexing:** The I/O bus read multiplexer `P33` (`io_bus_mux`) selects slot 9's data when `sel` is active, forwarding it to the CPU's write-back multiplexer `P25` (`wb_mux`) to update the destination register in `P12` (`rf_storage`).

## E1 Instruction trace: BGEU
Trace one **BGEU** instruction through the whole RC-V processor,
block by block (use docs/ARCHITECTURE.md and the simulator's --trace output).
List the blocks it passes through and the value on the main signals.

Instruction: `bgeu x10, x11, label` (`opcode = 7'b1100011`, `funct3 = 3'b111`, `rs1 = 10`, `rs2 = 11`, with `x10 = 0x0000000A` and `x11 = 0x00000005`, branch forward by +16 bytes):

1. **Instruction Fetch (IF):**
   - **`P14` (`pc_reg`):** Current program counter value `pc = 0x00000100` is driven onto the instruction address bus.
   - **`P30` (`boot_rom`):** Memory reads the 32-bit instruction word at `0x00000100`, outputting `instr`.
   - **`P03` (`pc_inc`):** Concurrently increments `pc` by 4, producing sequential next PC `pc4 = 0x00000104`.
2. **Instruction Decode (ID):**
   - **`P17` (`ifields`):** Splits `instr` into `opcode = 7'b1100011` (`0x63`), `funct3 = 3'b111`, `rs1 = 5'd10`, `rs2 = 5'd11`.
   - **`P19` (`imm_bju`):** Extracts and sign-extends the B-type immediate: $\{ \text{instr}[31], \text{instr}[7], \text{instr}[30:25], \text{instr}[11:8], 1'b0 \} \rightarrow \text{imm\_b} = +16$ (`0x00000010`).
   - **`P21` (`opclass_dec`):** Decodes opcode `7'b1100011`, asserting `is_branch = 1`.
   - **`P22`/`P23` $\rightarrow$ `P24` (`ctrl`):** Outputs control bundle: `c_branch = 1`, `c_regwrite = 0`, `c_memread = 0`, `c_memwrite = 0`, `c_asel_pc = 0`, `c_bsel_imm = 0`.
   - **`P13` (`rf_readmux`):** Reads `rs1 = 10` and `rs2 = 11` from register file `P12`, producing `r1 = 0x0000000A` (10) and `r2 = 0x00000005` (5).
3. **Execute (EX):**
   - **`P02` (`target_adder`):** Computes branch destination address: $\text{target\_pc} = \text{pc} + \text{imm\_b} = \text{0x00000100} + 16 = \text{0x00000110}$.
   - **`P09` (`branch_cmp`):** Receives operands `r1` and `r2` and `funct3 = 3'b111` (`BGEU`). Compares them using unsigned logic: since $10 \ge 5$, `ltu = 0`, and for `BGEU`, condition is met ($\text{take\_branch} = 1$).
4. **Memory (MEM):**
   - Control signals `c_memread = 0` and `c_memwrite = 0`: Data memory (`P29`) and MMIO peripherals remain inactive.
5. **Next PC & Write-back (WB):**
   - **`P16` (`pcsel_logic`):** Evaluates $\text{take} = \text{c\_branch} \cdot \text{take\_branch} = 1 \cdot 1 = 1$. It signals `P15` (`next_pc`) to select `target_pc` rather than `pc4`.
   - **`P15` (`next_pc`):** Routes `0x00000110` to the input of `P14`.
   - **`P14` (`pc_reg`):** On the next rising clock edge, `pc` latches to `0x00000110`.
   - Register write-back is disabled (`c_regwrite = 0`), leaving the register file untouched.

## E2 Neighbour review
Review the pull requests of P50 (Multiplier (shift and add)) and P52 (Binary-to-BCD converter). Paste the links to your review
comments here.

- **P50 (Multiplier (shift and add))** — owner `@pavan2008og` (Join issue: https://github.com/campus-sutra/rc-v/issues/29):
  - Review status: Pull request not yet submitted on `campus-sutra/rc-v`.
  - Planned review checks: I will review P50's shift-and-add state machine, checking that multi-cycle busy status (`STATUS[0]`) asserts correctly during computation, that writing to `START` properly loads the multiplicand and multiplier without race conditions, and that 32-bit unsigned multiplication matches expected truncation semantics. Review comment link will be added upon PR submission.
- **P52 (Binary-to-BCD converter)** — owner `@anuragstrong13-netizen` (Join issue: https://github.com/campus-sutra/rc-v/issues/18):
  - Review status: Pull request not yet submitted on `campus-sutra/rc-v`.
  - Planned review checks: I will inspect the double-dabble (shift-and-add-3) algorithm implementation in both the Digital circuit and Verilog, ensuring that each of the four decimal nibbles is checked for values $\ge 5$ before shifting, and verifying that edge cases ($0$ and $65535$) convert accurately to 5 BCD digits. Review comment link will be added upon PR submission.

## E3 Where my block sits
In two or three sentences: which layer of the computer is your block in
(gates / components / datapath / control / instruction set / memory / I/O),
which blocks feed it and which blocks use its output?

P51 sits in the **Memory and I/O layer** as an accelerated peripheral coprocessor at slot 9. It is fed by the CPU datapath and bus controller through address decoder `P31` (`addr_decode`) and memory write-data bus lines (`wdata`). Its output (`rdata`) feeds the I/O read bus multiplexer `P33` (`io_bus_mux`), which routes vector calculation results back to write-back multiplexer `P25` (`wb_mux`) and the processor's register file.

## E4 Syllabus map
Tick every syllabus topic your work touched (main units: Unit 3, Unit 5).

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
