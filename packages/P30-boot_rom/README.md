# P30 - Boot ROM

**Group:** D. Memory and bus · **Syllabus focus:** Unit 2 (Digital components), Unit 4 (Basic computer organisation), Unit 5 (Processors)
**Work:** hardware ●○○ + program ●●● = the same total as every other package

16384-word (64 KB) read-only memory with two read ports (instructions and constants). Its contents come from the file named by parameter INIT_FILE ($readmemh).

You hand in four files, all in this folder:

| File | What it is |
|---|---|
| `P30.dig` | your circuit in Digital |
| `p30_boot_rom.v` | the same block in Verilog |
| `p30.s` | your RISC-V program |
| `DOSSIER.md` | your answers (U1-U6, E1-E4) |

Do not change anything in `tests/` or outside this folder: the checker rejects it.

## 1. Digital circuit (`P30.dig`)

A ROM part holding the first 16 words of the boot program: sw/lib/crt0.s followed by sw/lib/boot_main.s and sw/lib/rcv_lib.s, assembled together (crt0's la instructions depend on what follows it). Assemble it (by hand or with tools/rcv/asm.py) and type the machine code into the ROM yourself.

| Direction | Name | Bits |
|---|---|---|
| input | `addr` | 4 |
| output | `data` | 32 |

Allowed parts: gates + multiplexer/decoder parts + ROM. The file already contains the pins and the
public tests: in Digital use **Tests → Run tests** (or F8).

## 2. Verilog module (`p30_boot_rom.v`)

The full-size block, exactly as the RC-V computer uses it:

| Direction | Name | Bits |
|---|---|---|
| input | `iaddr` | 14 |
| input | `daddr` | 14 |
| output | `idata` | 32 |
| output | `ddata` | 32 |

Combinational: outputs depend only on the current inputs.
The test bench is `tests/tb_p30_boot_rom.v`. The checker runs it with Icarus Verilog
when you push; you can also run it on your laptop (see docs/GETTING-STARTED.md).

## 3. RISC-V program (`p30.s`)

# P30 program: String table in ROM  (●●●)

In `.rodata` put a pointer table `.word` with the addresses of 5 strings, and the strings `ROM`, `RAM`, `UART`, `KEYBOARD`, `TIMER` right after each other (`.asciz`, in this order). Read indexes (decimal, one per line) until 9. For 0-4, print the string and its offset from the first string in hex; otherwise print `no such string`.
Output per index: `string <i>: <text> (offset <8 hex digits>)`.

Example input:
```
0
3
7
9
```
Output:
```
string 0: ROM (offset 00000000)
string 3: KEYBOARD (offset 0000000D)
no such string
```

You may use the library routines: rcv_read_dec, rcv_puts, rcv_print_udec, rcv_print_hex.
This exercises your block: the strings are constants that are read out of your boot ROM.

Your program is a subroutine: it starts at `p30_main` and returns with `ret`.
The checker runs it on the RC-V simulator with every `tests/program/*.in` file
as keyboard input and compares the terminal output with the matching `.out` file.

## 4. Dossier (`DOSSIER.md`)

Fill in every section. Your instruction to trace (E1) is **XOR**;
your review partners (E2) are P29 (Data memory) and P31 (Address decoder (memory map)).
