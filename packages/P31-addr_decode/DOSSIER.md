# P31 Address decoder (memory map) - dossier

## U1 Digital logic
The address decoder checks the upper bits of the 32-bit address (`addr[31:11]`) to determine which memory region is selected. Assuming `addr[31:18] == 0` (checked using a NOR gate, called `upper_zero`), the truth table for the region selection is:

| upper_zero | addr[17] | addr[16] | addr[15:14] | addr[15:11] | sel_rom | sel_ram | sel_io |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 1 | 0 | 0 | XX | XXXXX | 1 | 0 | 0 |
| 1 | 0 | 1 | 00 | XXXXX | 0 | 1 | 0 |
| 1 | 1 | 0 | 00 | 00000 | 0 | 0 | 1 |
| 0 | X | X | XX | XXXXX | 0 | 0 | 0 |

Simplified Boolean expressions:
- `upper_zero = ~(addr[31] | addr[30] | ... | addr[18])`
- `sel_rom = upper_zero & ~addr[17] & ~addr[16]`
- `sel_ram = upper_zero & ~addr[17] & addr[16] & ~addr[15] & ~addr[14]`
- `sel_io  = upper_zero & addr[17] & ~addr[16] & ~(addr[15] | addr[14] | addr[13] | addr[12] | addr[11])`

Gates needed: **NOT, AND, and NOR** gates (plus wiring splitters). No flip-flops are needed because the decoder is purely combinational.

## U2 Digital components
This block is a combinational **address decoder** built from **bit splitters** and basic logic gates (NOR, NOT, AND). Splitters break the 32-bit `addr` bus into:
- `addr[31:11]` fed into NOR/NOT/AND gates to generate `sel_rom`, `sel_ram`, and `sel_io`.
- `addr[10:6]` wired directly to the 5-bit `dev` output.
- `addr[5:2]` wired directly to the 4-bit `ridx` output.

No adders, registers, or memory blocks are used inside this component.

## U3 Data representation
Three test vectors:
1. **ROM access (`0x00000004`)**: Binary `00000000_00000000_00000000_00000100`, Decimal `4`. Outputs: `sel_rom = 1`, `sel_ram = 0`, `sel_io = 0`, `dev = 0`, `ridx = 1`.
2. **RAM access (`0x00010008`)**: Binary `00000000_00000001_00000000_00001000`, Decimal `65544`. Outputs: `sel_rom = 0`, `sel_ram = 1`, `sel_io = 0`, `dev = 0`, `ridx = 2`.
3. **I/O access (`0x00020044`)**: Binary `00000000_00000010_00000000_01000100`, Decimal `131140`. Outputs: `sel_rom = 0`, `sel_ram = 0`, `sel_io = 1`, `dev = 1`, `ridx = 1`.

**Overflow / sign extension risk:** Memory addresses are unsigned 32-bit values. In load/store instructions (`base + offset`), if the 12-bit immediate offset is sign-extended incorrectly or if the addition overflows 32 bits, the address can wrap around into an unmapped region (all selects `0`) or accidentally access ROM/I/O instead of RAM.

## U4 Computer organisation
This block works in two stages of the instruction cycle:
- **Fetch:** Every instruction fetch uses the PC address to select Boot ROM (`sel_rom = 1`).
- **Memory:** Load and store instructions (`lw`, `lh`, `lb`, `lhu`, `lbu`, `sw`, `sh`, `sb`) send the computed address to this decoder to select RAM (`sel_ram`) or a memory-mapped I/O device (`sel_io`).

## U5 Processors
RC-V (RISC-V) uses **memory-mapped I/O (MMIO)**, so one unified address decoder handles ROM, RAM, and I/O using normal load/store instructions.
- A **CISC processor** (like x86) often uses port-mapped I/O (`IN`/`OUT` instructions) with a separate I/O address space and an `M/IO#` control signal instead of decoding everything in one flat map.
- A **stack machine** operates on an implicit stack and often uses dedicated I/O opcodes.
- A **GPU** uses separate address spaces (global, shared, local, constant memory) and parallel memory controllers/coalescing units rather than a single scalar address decoder.

## U6 Memory and I/O
This block directly controls every memory access and I/O transfer. When the CPU puts a 32-bit address on the bus, the decoder asserts `sel_rom` for Boot ROM (`0x00000000–0x0000FFFF`), `sel_ram` for Data RAM (`0x00010000–0x00013FFF`), or `sel_io` for I/O (`0x00020000–0x000207FF`). During an I/O transfer, it also outputs `dev = addr[10:6]` to select the peripheral (such as UART, Keyboard, or GPIO) and `ridx = addr[5:2]` to select the specific register inside that peripheral.

## E1 Instruction trace: SRL
Example instruction: `srl x5, x6, x7` (R-type: opcode `0110011`, funct3 `101`, funct7 `0000000`), with `x6 = 0x80000000` and `x7 = 4`.
1. **Fetch:** PC outputs the instruction address in ROM -> **P31 Address decoder** sets `sel_rom = 1` -> **P30 Boot ROM** outputs the 32-bit `SRL` instruction -> **P32 Memory read selector** passes it to the CPU. PC updates to `PC + 4`.
2. **Decode:** Instruction decoder extracts `rd = x5`, `rs1 = x6`, `rs2 = x7`, `funct3 = 101`, `funct7 = 0000000`. Control sets `RegWrite = 1`, `ALUSrc = 0`, `MemRead = 0`, `MemWrite = 0`, and selects the `SRL` ALU operation. Register file outputs `rs1 = 0x80000000` and `rs2 = 4`.
3. **Execute:** The ALU/shifter shifts `0x80000000` right logically by `rs2[4:0] = 4` bits (filling left bits with `0`), producing `0x08000000`.
4. **Memory:** Idle (`MemRead = 0`, `MemWrite = 0`; P31 is not used for data access).
5. **Write-back:** Write-back mux selects the ALU result (`0x08000000`) and writes it to register `x5`.

## E2 Neighbour review
- P30 (Boot ROM): (Will add PR review comment link after reviewing P30's PR)
- P32 (Memory read selector): (Will add PR review comment link after reviewing P32's PR)

## E3 Where my block sits
My block sits in the **Memory and I/O (bus)** layer of the computer. It is fed by the 32-bit address bus (from the PC during fetch or from the ALU during load/store), and its outputs (`sel_rom`, `sel_ram`, `sel_io`, `dev`, `ridx`) drive the Boot ROM (P30), Data RAM (P29), Memory read selector (P32), and the I/O bus/peripherals (P33).

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
- [ ] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA
