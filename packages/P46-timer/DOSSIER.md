# P46 Timer — Dossier

## U1 Digital logic

The P46 timer combines sequential state elements (registers and counters) with combinational logic (comparators and multiplexers). It implements four memory-mapped registers: `COUNT` (offset 0), `CMP` (offset 4), `CTRL` (offset 8), and `STATUS` (offset 12). 

The core state transitions are governed by synchronous sequential logic on the positive clock edge (`posedge clk`):
- When `rst` is high, all internal registers (`count`, `cmp`, control flags, and `match_flag`) are cleared to `0`.
- When `ctrl_enable` is active (`1`), the 8-bit `count` register increments on every clock cycle.
- A combinational comparison (`count == cmp`) evaluates continuously; when equality is reached while the timer is enabled, the sticky `match_flag` (`STATUS` bit 0) is set to `1`.
- Bus writes (`sel && we`) decode the register index (`ridx`) to update individual configuration registers or clear flags.

## U2 Digital components

The Verilog and circuit design utilizes the following digital components:
- **Registers:** 8-bit registers for `count` and `cmp`, and single-bit/control registers for `ctrl_enable`, `ctrl_irq_en`, and `match_flag`.
- **Counter/Incrementer:** An arithmetic incrementer (`count + 1'b1`) to advance the time steps.
- **Comparator:** An equality comparator checking whether `count == cmp`.
- **Multiplexers / Decoders:** Combinational `case` statements acting as address decoders for write operations (`ridx` selection) and read multiplexers routing register values to `rdata`.
- **Bus Interface:** Standard RC-V memory-mapped interface signals (`sel`, `we`, `re`, `ridx`, `wdata`, `rdata`, and `irq`).

## U3 Data representation

The following examples illustrate how data is represented and transferred across the timer registers:

| Operation / State | Binary (32-bit or byte view) | Hexadecimal | Decimal (Unsigned) | Description |
|---|---|---|---:|---|
| Set Comparison Target (`CMP`) | `0000 0000 0000 0000 0000 0000 0000 0101` | `0x00000005` | 5 | Setting the target match value to 5 via `sw t0, 4(s0)` |
| Enable Timer Control (`CTRL`) | `0000 0000 0000 0000 0000 0000 0000 0001` | `0x00000001` | 1 | Setting bit 0 of CTRL to enable the counter |
| Read Status Flag (`STATUS`) | `0000 0000 0000 0000 0000 0000 0000 0001` | `0x00000001` | 1 | Polled match flag indicating the timer expired |

**Overflow and Sign Considerations:** 
The 8-bit `count` register naturally wraps around from `0xFF` (255) back to `0x00` (0) upon overflowing if left running. When transferring data between 32-bit CPU words (`wdata`/`rdata`) and 8-bit internal registers, byte masking (`wdata[7:0]`) ensures upper bits are ignored during stores, while zero-extension `{24'd0, count}` ensures clean unsigned word formatting during loads.

## U4 Computer organisation

The P46 timer operates primarily during the **memory** and **execute** stages of the instruction cycle when the CPU executes load (`lb`/`lw`) and store (`sb`/`sw`) instructions targeting the Slot 3 memory-mapped I/O address range (`0xFFFF00C0`). 

During initialization, store instructions configure the `CMP` and `CTRL` registers. During polling, load instructions read the `STATUS` register to check whether the match flag has been asserted. If interrupt capability is enabled (`ctrl_irq_en`), the `irq` output signal becomes active upon a match, directly interfacing with the processor's interrupt cycle handling.

## U5 Processors

- **CISC processor:** CISC architectures often feature dedicated, complex timer instructions or specialized peripheral control registers integrated directly into the instruction set architecture (ISA), rather than relying purely on memory-mapped load/store operations.
- **Stack machine:** A stack machine would push timer configuration parameters onto the hardware evaluation stack before invoking specialized peripheral setup routines, rather than using general-purpose registers and explicit memory addresses.
- **GPU:** GPUs manage time and synchronization via global performance counters or warp-level timing instructions rather than individual memory-mapped timer slots per compute lane.

RISC-V's uniform load/store architecture makes memory-mapped peripheral integration straightforward, treating the timer registers simply as memory addresses.

## U6 Memory and I/O

The P46 timer functions as a memory-mapped I/O (MMIO) peripheral assigned to Slot 3 (base address `0xFFFF00C0`). It participates directly in bus data transfers:
- **Writes:** When the CPU executes a store instruction (`sb` or `sw`) to offsets `+0` (`COUNT`), `+4` (`CMP`), `+8` (`CTRL`), or `+12` (`STATUS`), the address decoder asserts `sel` and `we`, capturing `wdata`.
- **Reads:** When the CPU executes a load instruction (`lb` or `lw`) from those same offsets, `sel` and `re` are asserted, and the timer multiplexes the requested register value onto `rdata`.

It does not utilize DMA; all interactions are handled via program-controlled I/O and polling (or interrupt requests via the `irq` line).

## E1 Instruction trace: LB (Reading STATUS)

Example instruction: `lb t1, 12(s0)` (machine code: `0x00C50303`), reading the timer `STATUS` register during `p46_poll_loop`.

Before execution, `s0 = 0xFFFF00C0` (Slot 3 base address) and the timer match has occurred (`STATUS` bit 0 = 1).

| Cycle | PC | Instruction | Operation |
|---|---|---|---|
| 102 | `0x210` | `0x00C50303` | Executes load byte from address `s0 + 12` (`STATUS`) |
| 103 | `0x214` | `0x00130313` | Executes `andi t1, t1, 1` to isolate the match flag |
| 104 | `0x218` | `0x00630463` | Executes `beqz t1, p46_poll_loop` (branch not taken as flag is 1) |

During the instruction cycle for the load instruction, the address generation unit computes `0xFFFF00CC`, the memory interface routes the request to Slot 3 (`ridx = 3`), the P46 timer outputs `{31'd0, match_flag}` on `rdata`, and the register file writes `1` into register `t1`.

## E2 Neighbour Review

### Review Partner 1: P45 – Hex Display Scanner

**Review Status:** Pending – Pull request was not available at the time of review.

The P45 implementation could not be reviewed because its pull request was not available in the repository when the review was conducted. No review comments were submitted.

### Review Partner 2: P47 – Interrupt Controller

**Review Status:** Pending – Pull request was not available at the time of review.

The P47 implementation could not be reviewed because its pull request was not available in the repository when the review was conducted. No review comments were submitted.

## E3 Where my block sits

My block sits in the memory-mapped I/O (MMIO) peripheral layer of the computer system. It is fed by the processor data bus and address decoder signals (`clk`, `rst`, `sel`, `we`, `re`, `ridx`, `wdata`), and it outputs register data (`rdata`) back to the datapath along with an interrupt request line (`irq`) to the interrupt control logic.

## E4 Syllabus map

The following topics are directly touched by the P46 timer work:

- [ ] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers) — used for address decoding and data multiplexing
- [x] Flip-flops, registers, counters — used for `count`, `cmp`, and state flags
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic — byte/word data handling and offsets
- [x] Bus organisation, instruction codes and formats — MMIO slot architecture and load/store instructions
- [x] Instruction cycle, hardwired vs microprogrammed control — execution of load/store and bus handshaking
- [x] Interrupts and the interrupt cycle — `irq` output generation
- [ ] Pipelining
- [x] Register organisation, stack, addressing modes — base-plus-offset addressing and stack preservation in assembly
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA — memory-mapped I/O polling implementation
