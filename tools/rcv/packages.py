"""The 66 work packages of the RC-V project.

Each package = one hardware block (a Digital circuit + its Verilog module)
+ one RISC-V program + a short dossier. Hardware weight (1-3) and program
weight (3-1) always add up to 4, so every student has the same amount of work.

Port lists use "dir name:width" (width 1 if omitted). A block with a `clk`
input is clocked. `dig` describes the Digital circuit, which is often a
scaled-down version of the full Verilog module.
"""
from . import blocks as B
from . import devices as D

GROUPS = {
    "A": "Arithmetic and logic",
    "B": "Registers and program counter",
    "C": "Decode and control",
    "D": "Memory and bus",
    "E": "Traps and interrupts",
    "F": "Input/output devices",
    "G": "Measurement and support devices",
}

DEV_PORTS = "in clk, in rst, in sel, in we, in re, in ridx:4, in wdata:32, out rdata:32"

GATES = "gates"            # And Or Not XOr NAnd NOr XNOr + wiring
GATES_MUX = "gates+mux"    # ... + Multiplexer, Decoder, Demultiplexer
GATES_FF = "gates+ff"      # ... + D/JK/T flip-flops
GATES_MUX_FF = "gates+mux+ff"
ARITH = "gates+mux+ff+arith"  # ... + Add, Sub, Comparator, Neg
ROM = "gates+mux+rom"


def P(id, slug, title, group, units, hw, ports, model, summary, dig, gen=None, slot=None):
    return dict(id=id, slug=slug, title=title, group=group, units=units, hw=hw, prog=4 - hw,
                ports=ports, model=model, summary=summary, dig=dig, gen=gen or {}, slot=slot)


def DIG(ports, model, parts, note, gen=None):
    return dict(ports=ports, model=model, parts=parts, note=note, gen=gen or {})


PACKAGES = [
    # ------------------------------------------------------------------ A
    P(1, "alu_addsub", "ALU adder/subtractor", "A", [1, 2, 3], 2,
      "in a:32, in b:32, in sub, out y:32, out c, out v", B.alu_addsub,
      "Adds a+b, or a-b when sub=1 (a + ~b + 1). c = carry out, v = signed overflow.",
      DIG("in a:8, in b:8, in sub, out y:8, out c, out v", lambda i: B.alu_addsub(i, 8), GATES,
          "8-bit version. Build a full adder from gates first, then chain eight of them; "
          "XOR gates on b make the subtractor.")),
    P(2, "target_adder", "Branch-target adder (carry look-ahead)", "A", [2, 3], 3,
      "in a:32, in b:32, out y:32", B.target_adder,
      "Computes pc + immediate for branches and jal, using carry look-ahead instead of a ripple chain.",
      DIG("in a:8, in b:8, out y:8", lambda i: B.target_adder(i, 8), GATES,
          "8-bit version from two 4-bit carry look-ahead blocks (generate/propagate logic, "
          "C1..C4 equations). No ripple chain inside a block.")),
    P(3, "pc_inc", "PC incrementer", "A", [2], 1,
      "in pc:32, out pc4:32", B.pc_inc,
      "pc + 4, the address of the next instruction.",
      DIG("in pc:8, out pc4:8", lambda i: B.pc_inc(i, 8), GATES,
          "8-bit version from half adders. Notice bits 0 and 1 never change: why?")),
    P(4, "alu_logic", "ALU logic unit", "A", [1, 2], 1,
      "in a:32, in b:32, in op:2, out y:32", B.alu_logic,
      "op 0 = AND, 1 = OR, 2 = XOR, 3 = 0.",
      DIG("in a:4, in b:4, in op:2, out y:4", lambda i: B.alu_logic(i, 4), GATES_MUX,
          "4-bit version: one bit-slice of AND/OR/XOR gates and a 4-to-1 multiplexer, copied 4 times.")),
    P(5, "shift_left", "Left barrel shifter", "A", [2], 2,
      "in a:32, in sh:5, out y:32", B.shift_left,
      "y = a << sh, built as a barrel shifter (stages that shift by 1, 2, 4, 8, 16).",
      DIG("in a:8, in sh:3, out y:8", lambda i: B.shift_left(i, 8), GATES_MUX,
          "8-bit version: three stages of 2-to-1 multiplexers (shift by 1, 2, 4).")),
    P(6, "shift_right", "Right barrel shifter", "A", [2, 3], 2,
      "in a:32, in sh:5, in arith, out y:32", B.shift_right,
      "y = a >> sh. arith=1 copies the sign bit in from the left (SRA), arith=0 shifts in zeros (SRL).",
      DIG("in a:8, in sh:3, in arith, out y:8", lambda i: B.shift_right(i, 8), GATES_MUX,
          "8-bit version: three multiplexer stages; the bit shifted in is a7 AND arith.")),
    P(7, "slt_unit", "Less-than unit (signed and unsigned)", "A", [1, 3], 2,
      "in a:32, in b:32, out lt, out ltu", B.slt_unit,
      "lt = a < b as signed (2's complement) numbers, ltu = a < b as unsigned numbers.",
      DIG("in a:4, in b:4, out lt, out ltu", lambda i: B.slt_unit(i, 4), GATES,
          "4-bit version from gates: design a 1-bit comparator cell with a K-map, cascade it, "
          "then fix the sign bit for the signed result.")),
    P(8, "alu_select", "ALU result selector", "A", [2], 1,
      "in aluop:4, in add_y:32, in logic_y:32, in shl_y:32, in shr_y:32, in lt, in ltu, out y:32, out zero",
      B.alu_select,
      "Chooses the ALU result for the operation (ADD/SUB from the adder, AND/OR/XOR from the logic "
      "unit, shifts, SLT/SLTU as 0 or 1). zero = (y == 0).",
      DIG("in aluop:4, in add_y:4, in logic_y:4, in shl_y:4, in shr_y:4, in lt, in ltu, out y:4, out zero",
          lambda i: B.alu_select(i, 4), GATES_MUX,
          "4-bit version: decode aluop into a select code, then multiplexers; zero is a NOR of all bits."),
      gen={"aluop": list(range(10))}),
    P(9, "branch_cmp", "Branch comparator", "A", [1, 3, 4], 2,
      "in a:32, in b:32, in funct3:3, out take", B.branch_cmp,
      "take = 1 when the branch condition holds: BEQ(0) BNE(1) BLT(4) BGE(5) BLTU(6) BGEU(7).",
      DIG("in a:4, in b:4, in funct3:3, out take", lambda i: B.branch_cmp(i, 4), GATES_MUX,
          "4-bit version: equality from XNOR gates, signed/unsigned less-than, then select by funct3."),
      gen={"funct3": [0, 1, 4, 5, 6, 7]}),
    P(10, "aluctl", "ALU control", "A", [1, 4], 2,
      "in is_op, in is_opimm, in funct3:3, in funct7b5, out aluop:4", B.aluctl,
      "Turns funct3/funct7 into the ALU operation code (ADD=0 SUB=1 AND=2 OR=3 XOR=4 SLL=5 SRL=6 "
      "SRA=7 SLT=8 SLTU=9). Non-ALU instructions use ADD. ADDI never subtracts.",
      DIG("in is_op, in is_opimm, in funct3:3, in funct7b5, out aluop:4", B.aluctl, GATES,
          "Full size, gates only: write the truth table, simplify each output bit with a K-map."),
      gen={"_onehot_opt": ["is_op", "is_opimm"]}),
    # ------------------------------------------------------------------ B
    P(11, "rf_decoder", "Register-file write decoder", "B", [2], 2,
      "in we, in rd:5, out wen:32", B.rf_decoder,
      "One-hot write enables: wen[rd] = we, except register x0 which is never written.",
      DIG("in we, in rd:5, out wen:32", B.rf_decoder, GATES_MUX,
          "Full size: build the 5-to-32 decoder from one 2-to-4 and four 3-to-8 Decoder parts plus AND gates.")),
    P(12, "rf_storage", "Register-file storage", "B", [1, 2], 2,
      "in clk, in rst, in wen:32, in wd:32, out q_flat:1024", B.RfStorage,
      "32 registers of 32 bits. On the clock edge every register whose wen bit is 1 loads wd; rst=1 clears all. "
      "Register 0 always stays 0. q_flat holds all registers side by side (register k in bits 32k+31..32k).",
      DIG("in clk, in rst, in wen:4, in wd:4, out q_flat:16", lambda: B.RfStorage(4, 4), GATES_MUX_FF,
          "4 registers x 4 bits from D flip-flops; register 0 is wired to 0.")),
    P(13, "rf_readmux", "Register-file read port", "B", [2], 2,
      "in q_flat:1024, in ra:5, out rd:32", B.rf_readmux,
      "Selects register ra out of q_flat. The processor uses two copies (rs1 and rs2).",
      DIG("in q_flat:16, in ra:2, out rd:4", lambda i: B.rf_readmux(i, 4, 4), GATES,
          "4 registers x 4 bits: build the 4-to-1 multiplexer from AND/OR gates (no Multiplexer part).")),
    P(14, "pc_reg", "Program counter register", "B", [1, 2, 4], 1,
      "in clk, in rst, in en, in d:32, out q:32", B.PcReg,
      "Loads d on the clock edge when en=1; rst=1 (synchronous) sets it to 0, the reset address.",
      DIG("in clk, in rst, in en, in d:8, out q:8", lambda: B.PcReg(8), GATES_FF,
          "8-bit version from D flip-flops with a 2-to-1 hold/load choice built from gates.")),
    # ------------------------------------------------------------------ C
    P(15, "next_pc", "Next-PC selector", "C", [4], 1,
      "in sel:3, in pc4:32, in target:32, in jalr_y:32, in mtvec:32, in mepc:32, out npc:32", B.next_pc,
      "sel 0 = pc+4, 1 = branch/jal target, 2 = jalr result with bit 0 cleared, 3 = mtvec (trap), "
      "4 = mepc (mret). Other values give pc+4.",
      DIG("in sel:3, in pc4:4, in target:4, in jalr_y:4, in mtvec:4, in mepc:4, out npc:4",
          lambda i: B.next_pc(i, 4), GATES_MUX, "4-bit version with an 8-to-1 multiplexer."),
      gen={"sel": [0, 1, 2, 3, 4, 5]}),
    P(16, "pcsel_logic", "Next-PC decision logic", "C", [1, 4], 2,
      "in trap, in is_mret, in is_jalr, in is_jal, in is_branch, in take, out sel:3", B.pcsel_logic,
      "Priority: trap > mret > jalr > (jal or taken branch) > pc+4. Produces the sel code for P15.",
      DIG("in trap, in is_mret, in is_jalr, in is_jal, in is_branch, in take, out sel:3", B.pcsel_logic, GATES,
          "Full size, gates only: truth table with don't-cares, then K-maps.")),
    P(17, "ifields", "Instruction field splitter", "C", [4], 1,
      "in instr:32, out opcode:7, out rd:5, out funct3:3, out rs1:5, out rs2:5, out funct7:7, out csr:12",
      B.ifields, "Splits an instruction word into its fields (R/I/S/B/U/J formats share these positions).",
      DIG("in instr:32, out opcode:7, out rd:5, out funct3:3, out rs1:5, out rs2:5, out funct7:7, out csr:12",
          B.ifields, "wiring", "Full size, Splitters only. Label every field.")),
    P(18, "imm_is", "Immediate generator I/S", "C", [3, 4], 1,
      "in instr:32, out imm_i:32, out imm_s:32", B.imm_is,
      "Sign-extended 12-bit immediates of I-type (loads, ADDI, JALR) and S-type (stores).",
      DIG("in instr:32, out imm_i:32, out imm_s:32", B.imm_is, "wiring",
          "Full size, Splitters only: sign extension is just copying bit 31 into the upper bits.")),
    P(19, "imm_bju", "Immediate generator B/J/U", "C", [3, 4], 2,
      "in instr:32, out imm_b:32, out imm_j:32, out imm_u:32", B.imm_bju,
      "Branch (13-bit, even), jump (21-bit, even) and upper (20 bits << 12) immediates; the scrambled "
      "bit order of B and J must be put back together.",
      DIG("in instr:32, out imm_b:32, out imm_j:32, out imm_u:32", B.imm_bju, "wiring",
          "Full size, Splitters only.")),
    P(20, "imm_select", "Immediate selector", "C", [4], 1,
      "in immsel:3, in imm_i:32, in imm_s:32, in imm_b:32, in imm_u:32, in imm_j:32, out imm:32",
      B.imm_select, "immsel 0 = I, 1 = S, 2 = B, 3 = U, 4 = J; others give 0.",
      DIG("in immsel:3, in imm_i:4, in imm_s:4, in imm_b:4, in imm_u:4, in imm_j:4, out imm:4",
          lambda i: B.imm_select(i, 4), GATES_MUX, "4-bit version with a multiplexer."),
      gen={"immsel": [0, 1, 2, 3, 4, 5]}),
    P(21, "opclass_dec", "Opcode class decoder", "C", [1, 4], 2,
      "in instr:32, out is_lui, out is_auipc, out is_jal, out is_jalr, out is_branch, out is_load, "
      "out is_store, out is_opimm, out is_op, out is_system, out is_ecall, out is_mret",
      B.opclass_dec,
      "One output per instruction class from the 7-bit opcode, plus exact matches for ECALL "
      "(0x00000073) and MRET (0x30200073).",
      DIG("in instr:32, out is_lui, out is_auipc, out is_jal, out is_jalr, out is_branch, out is_load, "
          "out is_store, out is_opimm, out is_op, out is_system, out is_ecall, out is_mret",
          B.opclass_dec, ARITH, "Full size: AND gates with inverted inputs for each opcode; a "
                                "Comparator with a Const is allowed for ECALL/MRET."),
      gen={"instr": "instr"}),
    P(22, "ctrl_hw", "Hardwired control unit", "C", [1, 4], 3,
      "in is_lui, in is_auipc, in is_jal, in is_jalr, in is_branch, in is_load, in is_store, "
      "in is_opimm, in is_op, in is_system, out ctrl:16", B.ctrl_hw,
      "Produces the 16-bit control word (regwrite asel_pc bsel_imm a_zero memread memwrite wbsel[2] "
      "immsel[3] is_branch is_jal is_jalr is_csr) from the class signals, with logic gates.",
      DIG("in is_lui, in is_auipc, in is_jal, in is_jalr, in is_branch, in is_load, in is_store, "
          "in is_opimm, in is_op, in is_system, out ctrl:16", B.ctrl_hw, GATES,
          "Full size, gates only: one OR-of-classes equation per control bit."),
      gen={"_onehot": ["is_lui", "is_auipc", "is_jal", "is_jalr", "is_branch", "is_load", "is_store",
                       "is_opimm", "is_op", "is_system"]}),
    P(23, "ctrl_rom", "Microprogrammed control (control ROM)", "C", [2, 4], 2,
      "in op_hi:5, out ctrl:16", B.ctrl_rom,
      "The same 16-bit control word, read from a 32-entry control memory addressed by opcode[6:2]. "
      "Unused opcodes give 0.",
      DIG("in op_hi:5, out ctrl:16", B.ctrl_rom, ROM,
          "Full size: a ROM part (5 address bits, 16 data bits); you work out and enter the contents.")),
    P(24, "ctrl_check", "Control selector and checker", "C", [4], 1,
      "in ctrl_hw:16, in ctrl_rom:16, in use_rom, out ctrl:16, out mismatch", B.ctrl_check,
      "Passes on one control unit's word (use_rom selects) and raises mismatch when the hardwired "
      "and microprogrammed units disagree.",
      DIG("in ctrl_hw:16, in ctrl_rom:16, in use_rom, out ctrl:16, out mismatch", B.ctrl_check, GATES_MUX,
          "Full size: multiplexer plus XOR/OR gates."),
      gen={"_same_often": ["ctrl_hw", "ctrl_rom"]}),
    P(25, "wb_mux", "Write-back selector", "C", [4], 1,
      "in wbsel:2, in alu_y:32, in mem_val:32, in pc4:32, in csr_rd:32, out wd:32", B.wb_mux,
      "Chooses what is written to the register: 0 ALU result, 1 loaded value, 2 pc+4 (jal/jalr), 3 CSR.",
      DIG("in wbsel:2, in alu_y:4, in mem_val:4, in pc4:4, in csr_rd:4, out wd:4",
          lambda i: B.wb_mux(i, 4), GATES, "4-bit version from gates (no Multiplexer part).")),
    P(26, "opab_mux", "ALU operand selector", "C", [4, 5], 1,
      "in a_zero, in asel_pc, in bsel_imm, in rs1:32, in pc:32, in rs2:32, in imm:32, out a:32, out b:32",
      B.opab_mux,
      "a = 0 (LUI) or pc (AUIPC) or rs1; b = immediate or rs2. This is where addressing modes "
      "(register, immediate, PC-relative) are chosen.",
      DIG("in a_zero, in asel_pc, in bsel_imm, in rs1:4, in pc:4, in rs2:4, in imm:4, out a:4, out b:4",
          lambda i: B.opab_mux(i, 4), GATES_MUX, "4-bit version.")),
    # ------------------------------------------------------------------ D
    P(27, "store_align", "Store aligner", "D", [2, 6], 2,
      "in funct3:3, in addr_lo:2, in rs2:32, out wdata:32, out be:4", B.store_align,
      "SW: wdata = rs2, be = 1111. SB: the low byte copied into all four lanes and be = one-hot byte "
      "lane from addr_lo (little-endian).",
      DIG("in funct3:3, in addr_lo:2, in rs2:32, out wdata:32, out be:4", B.store_align, GATES_MUX,
          "Full size: a Decoder for the byte lane, multiplexers for the data."),
      gen={"funct3": [0, 2]}),
    P(28, "load_extend", "Load extender", "D", [2, 3, 6], 2,
      "in raw:32, in addr_lo:2, in funct3:3, out val:32", B.load_extend,
      "LW (2): the word. LB (0): byte lane addr_lo, sign-extended. LBU (4): the same byte, zero-extended.",
      DIG("in raw:32, in addr_lo:2, in funct3:3, out val:32", B.load_extend, GATES_MUX,
          "Full size: a byte multiplexer and sign-extension logic."),
      gen={"funct3": [0, 2, 4]}),
    P(29, "data_ram", "Data memory", "D", [2, 6], 2,
      "in clk, in we, in addr:12, in be:4, in wdata:32, out rdata:32", B.DataRam,
      "4096 words. Reading is immediate (rdata = mem[addr]); on the clock edge, if we=1, the bytes "
      "whose be bit is 1 are written.",
      DIG("in clk, in we, in addr:2, in wdata:8, out rdata:8", lambda: _SmallRam(), GATES_MUX_FF,
          "4 words x 8 bits from D flip-flops: address decoder for writing, multiplexer for reading.")),
    P(30, "boot_rom", "Boot ROM", "D", [2, 4, 5], 1,
      "in iaddr:14, in daddr:14, out idata:32, out ddata:32", None,
      "16384-word (64 KB) read-only memory with two read ports (instructions and constants). Its contents come "
      "from the file named by parameter INIT_FILE ($readmemh).",
      DIG("in addr:4, out data:32", "bootrom", ROM,
          "A ROM part holding the first 16 words of the boot program: sw/lib/crt0.s followed by "
          "sw/lib/boot_main.s and sw/lib/rcv_lib.s, assembled together (crt0's la instructions depend "
          "on what follows it). Assemble it (by hand or with tools/rcv/asm.py) and type the machine "
          "code into the ROM yourself.")),
    P(31, "addr_decode", "Address decoder (memory map)", "D", [2, 6], 2,
      "in addr:32, out sel_rom, out sel_ram, out sel_io, out dev:5, out ridx:4", B.addr_decode,
      "ROM 0x00000000-0x0000FFFF, RAM 0x00010000-0x00013FFF, I/O 0x00020000-0x000207FF "
      "(dev = address bits 10..6, ridx = bits 5..2).",
      DIG("in addr:32, out sel_rom, out sel_ram, out sel_io, out dev:5, out ridx:4", B.addr_decode, GATES,
          "Full size: Splitters and gates comparing the upper address bits."),
      gen={"addr": "addr"}),
    P(32, "read_mux", "Memory read selector", "D", [2, 6], 1,
      "in sel_rom, in sel_ram, in sel_io, in rom_d:32, in ram_d:32, in io_d:32, out rdata:32", B.read_mux,
      "Passes the data of the selected region (ROM, RAM or I/O); nothing selected gives 0.",
      DIG("in sel_rom, in sel_ram, in sel_io, in rom_d:4, in ram_d:4, in io_d:4, out rdata:4",
          lambda i: B.read_mux(i, 4), GATES, "4-bit version from AND/OR gates."),
      gen={"_onehot_opt": ["sel_rom", "sel_ram", "sel_io"]}),
    P(33, "io_bus_mux", "I/O read bus", "D", [2, 6], 1,
      "in dev_flat:1024, in dev:5, out rdata:32", lambda i: B.io_bus_mux(i, 32, 32),
      "Selects the read data of device slot dev out of all 32 devices' data (slot k in bits 32k+31..32k).",
      DIG("in dev_flat:16, in dev:2, out rdata:4", lambda i: B.io_bus_mux(i, 4, 4), GATES_MUX,
          "4 devices x 4 bits.")),
    P(34, "bus_arbiter", "Bus arbiter (CPU vs DMA)", "D", [6], 2,
      "in dma_req, in cpu_addr:32, in cpu_wdata:32, in cpu_we, in cpu_be:4, in dma_addr:32, in dma_wdata:32, "
      "in dma_we, out grant, out stall, out addr:32, out wdata:32, out we, out be:4", B.bus_arbiter,
      "When the DMA controller requests the bus it gets it (cycle stealing): the processor stalls and "
      "the memory sees the DMA address/data; otherwise the processor's.",
      DIG("in dma_req, in cpu_addr:4, in cpu_wdata:4, in cpu_we, in cpu_be:4, in dma_addr:4, in dma_wdata:4, "
          "in dma_we, out grant, out stall, out addr:4, out wdata:4, out we, out be:4",
          B.bus_arbiter, GATES_MUX, "4-bit version.")),
    P(35, "cache_tags", "Cache tag store", "D", [6], 3,
      "in clk, in rst, in access, in addr:32, out hit", B.CacheTags,
      "Direct-mapped cache directory: 16 lines of 16 bytes (index = addr[7:4], tag = addr[31:8]). "
      "hit = the line is valid and its tag matches (only while access=1). Every access fills the line.",
      DIG("in clk, in rst, in access, in addr:8, out hit", lambda: _SmallCache(), ARITH,
          "Scaled: 4 lines (index = addr[3:2]), tag = addr[7:4]; valid bits and tags in D flip-flops, "
          "a Comparator per line or one after a multiplexer.")),
    P(36, "cache_stats", "Cache statistics counters", "D", [6], 1,
      DEV_PORTS + ", in access, in hit", B.CacheStatsBlock,
      "I/O device (slot 7): HITS, MISSES, CLEAR. Counts each access as a hit or a miss.",
      DIG("in clk, in rst, in access, in hit, in clear, out hits:8, out misses:8", lambda: _SmallCounts(),
          GATES_MUX_FF, "Two 8-bit counters with clear, from flip-flops (no Counter part)."),
      slot=7),
    # ------------------------------------------------------------------ E
    P(37, "csr_file", "Control and status registers", "E", [4, 6], 3,
      "in clk, in rst, in addr:12, in we, in wdata:32, in trap, in cause:32, in pc:32, in mret, "
      "out rdata:32, out mtvec:32, out mepc:32, out mie", B.CsrFile,
      "mstatus (MIE bit 3, MPIE bit 7), mtvec, mscratch, mepc, mcause. On trap: mepc=pc, mcause=cause, "
      "MPIE=MIE, MIE=0. On mret: MIE=MPIE, MPIE=1. Otherwise a CSR write when we=1.",
      DIG("in clk, in rst, in we, in wdata:8, in trap, in mret, in set_mie, out mtvec:8, out mie, out mpie",
          lambda: _SmallCsr(), GATES_MUX_FF,
          "Scaled: an 8-bit mtvec register and the MIE/MPIE flip-flops with trap and mret behaviour.")),
    P(38, "csr_op", "CSR read-modify-write", "E", [4], 1,
      "in funct3:3, in rs1_val:32, in rs1_idx:5, in old:32, out new_val:32, out write", B.csr_op,
      "CSRRW(1): new_val = rs1. CSRRS(2): new_val = old | rs1. CSRRC(3): new_val = old & ~rs1. RS/RC with rs1 = x0 "
      "do not write.",
      DIG("in funct3:3, in rs1_val:4, in rs1_idx:5, in old:4, out new_val:4, out write",
          lambda i: _mask_out(B.csr_op(i), {"new_val": 4}), GATES_MUX, "4-bit data version."),
      gen={"funct3": [1, 2, 3]}),
    P(39, "trap_ctrl", "Trap controller", "E", [4], 2,
      "in stall, in irq, in irq_cause:5, in mie, in illegal, in is_ecall, out trap, out cause:32",
      B.trap_ctrl,
      "Decides whether this cycle traps: an enabled interrupt (cause 0x80000010 + irq_cause), else an "
      "illegal instruction (2), else ECALL (11). Never while stalled.",
      DIG("in stall, in irq, in irq_cause:5, in mie, in illegal, in is_ecall, out trap, out cause:32",
          B.trap_ctrl, ARITH, "Full size: gates plus an adder for 0x80000010 + irq_cause (or wiring)."),
      gen={"irq_cause": [0, 1, 2, 3, 4]}),
    P(40, "illegal_detect", "Illegal-instruction detector", "E", [4, 5], 2,
      "in instr:32, out illegal", B.illegal_detect,
      "1 for any word that is not one of the RC-V instructions (see docs/ISA.md), e.g. 0x00000000.",
      DIG("in instr:32, out illegal", B.illegal_detect, ARITH,
          "Full size: decode opcode/funct3/funct7 with gates (Comparators with Consts allowed)."),
      gen={"instr": "instr"}),
    # ------------------------------------------------------------------ F
    P(41, "uart_tx", "Terminal output (UART)", "F", [6], 2,
      DEV_PORTS + ", out tx_valid, out tx_char:8", B.UartBlock,
      "Slot 0: TXDATA (write a character), TXSTATUS bit0 = ready. After accepting a character the "
      "terminal is busy for 4 cycles; writes while busy are lost. tx_valid/tx_char show the character "
      "accepted at the last clock edge.",
      DIG("in clk, in rst, in write, out ready, out accept", lambda: _SmallUart(), GATES_MUX_FF,
          "The busy logic: a 3-bit down counter loaded with 4 when a write is accepted."), slot=0),
    P(42, "kbd_rx", "Keyboard input", "F", [6], 2,
      DEV_PORTS + ", in ext_valid, in ext_char:8, out ext_take, out irq", B.KbdBlock,
      "Slot 1: RXDATA (read: the character, which leaves the buffer), RXSTATUS bit0 = character waiting, "
      "PEEK (read without removing). A new key (ext_valid/ext_char) is taken (ext_take=1) when the "
      "buffer is empty and RXDATA is not being read. irq = character waiting.",
      DIG("in clk, in rst, in ext_valid, in ext_char:8, in pop, out data:8, out full, out take",
          lambda: _SmallKbd(), GATES_MUX_FF, "The one-character buffer and its full flag."), slot=1),
    P(43, "gpio", "LEDs, display register and buttons", "F", [2, 6], 1,
      DEV_PORTS + ", in buttons:8, out leds:16, out seg:32", B.GpioBlock,
      "Slot 2: LEDS (16 bits, read/write), SEG (32 bits, read/write, shown on the hex display), "
      "BUTTONS (read the 8 button inputs).",
      DIG("in clk, in rst, in we, in ridx:2, in wdata:8, in buttons:8, out rdata:8, out leds:8",
          lambda: _SmallGpio(), GATES_MUX_FF, "8-bit LED register plus the read multiplexer."), slot=2),
    P(44, "seg7_decoder", "Seven-segment decoder", "F", [1, 2], 2,
      "in hex:4, out seg:7", B.seg7,
      "Hex digit to segments gfedcba (active high), e.g. 0 -> 0x3F, A -> 0x77.",
      DIG("in hex:4, out seg:7", B.seg7, GATES,
          "Full size, gates only: seven 4-variable K-maps, one per segment.")),
    P(45, "hex_display", "Hex display scanner", "F", [2, 6], 1,
      "in clk, in rst, in value:32, out digit:4, out anode:8", B.HexDisplay,
      "Shows one digit at a time: each clock moves to the next of 8 digits; digit = that nibble of "
      "value, anode = one-hot digit position.",
      DIG("in clk, in rst, in value:16, out digit:4, out anode:4", lambda: B.HexDisplay(4), GATES_MUX_FF,
          "4 digits: a 2-bit counter, a 2-to-4 decoder for the anodes and a multiplexer for the nibble.")),
    P(46, "timer", "Timer", "F", [6], 2,
      DEV_PORTS + ", out irq", lambda: B.IrqOut(D.Timer),
      "Slot 3: COUNT, CMP, CTRL (bit0 enable, bit1 interrupt enable), STATUS bit0 = match (set when "
      "COUNT == CMP while enabled, cleared by writing STATUS). irq = match AND CTRL bit1.",
      DIG("in clk, in rst, in en, in load, in d:8, in cmp:8, in clr, out count:8, out match",
          lambda: _SmallTimer(), ARITH, "8-bit counter with load, an 8-bit comparator and the sticky match flag."),
      slot=3),
    P(47, "irq_ctrl", "Interrupt controller", "F", [2, 4, 6], 2,
      DEV_PORTS + ", in lines:4, out irq, out cause:5", B.IrqBlock,
      "Slot 4: PENDING (sources: 0 timer, 1 keyboard, 2 DMA, 3 stack guard, 4 software), MASK, CAUSE "
      "(highest-priority = lowest-numbered pending and unmasked source, 31 if none), SWI.",
      DIG("in lines:5, in mask:5, out irq, out cause:5", lambda i: _irq_comb(i), GATES,
          "The priority encoder: masking AND gates and a 5-input priority encoder from gates."),
      slot=4),
    P(48, "dma", "DMA controller", "F", [6], 3,
      DEV_PORTS + ", out req, out m_addr:32, out m_we, out m_wdata:32, in m_rdata:32, out irq", B.DmaBlock,
      "Slot 5: SRC, DST, LEN (words), CTRL (bit0 start, bit1 interrupt enable), STATUS (bit0 busy, "
      "bit1 done). Copies LEN words, each in a READ cycle and a WRITE cycle stolen from the processor.",
      DIG("in clk, in rst, in start, in len:4, out busy, out phase, out done", lambda: _SmallDma(), GATES_MUX_FF,
          "The control FSM: idle/read/write states and a 4-bit length counter."), slot=5),
    P(49, "perf_counters", "Performance counters", "G", [4, 5], 1,
      DEV_PORTS + ", in commit", lambda: B.DeviceBlock(D.Perf),
      "Slot 6: CYCLE (every clock), INSTRET (every committed instruction), CLEAR. CPI = CYCLE / INSTRET.",
      DIG("in clk, in rst, in commit, in clear, out cycle:8, out instret:8", lambda: _SmallPerf(), GATES_MUX_FF,
          "Two 8-bit counters from flip-flops."), slot=6),
    P(50, "mul_unit", "Multiplier (shift and add)", "G", [3, 5], 3,
      DEV_PORTS, lambda: B.DeviceBlock(D.Mul),
      "Slot 8: A, B, CTRL (write bit0 = start), STATUS bit0 busy, RESULT. Multiplies in 32 cycles, one "
      "bit of B per cycle.",
      DIG("in clk, in rst, in start, in a:4, in b:4, out result:8, out busy", lambda: _SmallMul(), ARITH,
          "4 x 4 bits in 4 cycles: accumulator, shift registers and an adder."), slot=8),
    P(51, "simd_unit", "Four-lane vector unit (mini GPU)", "G", [3, 5], 1,
      DEV_PORTS, lambda: B.DeviceBlock(D.Simd),
      "Slot 9: A, B, SUM, MAX, SUB treat each word as four 8-bit lanes and work on all lanes at once, "
      "the idea behind GPUs.",
      DIG("in a:8, in b:8, out sum:8, out max:8", lambda i: _simd_small(i), ARITH,
          "2 lanes of 4 bits: per-lane adders and comparators (Add/Comparator parts allowed)."), slot=9),
    P(52, "bcd_unit", "Binary-to-BCD converter", "G", [3], 2,
      DEV_PORTS, lambda: B.DeviceBlock(D.Bcd),
      "Slot 10: BIN (16 bits), BCD (five packed decimal digits of BIN), using the double-dabble "
      "(shift and add 3) method.",
      DIG("in bin:8, out bcd:12", lambda i: {"bcd": D.to_bcd(i["bin"], 3)}, ARITH,
          "8-bit version: shift-and-add-3 cells (if a digit >= 5 add 3)."), slot=10),
    P(53, "watchdog", "Watchdog timer", "G", [6], 1,
      DEV_PORTS, lambda: B.DeviceBlock(D.Wdt),
      "Slot 11: LOAD, CTRL bit0 enable, STATUS bit0 = bite, COUNT, KICK. Counts down; reaching 0 bites "
      "and reloads. A program must keep kicking it.",
      DIG("in clk, in rst, in en, in kick, in load:8, out count:8, out bite", lambda: _SmallWdt(), ARITH,
          "8-bit down counter with reload and the sticky bite flag."), slot=11),
    P(54, "rng_lfsr", "Random numbers (LFSR)", "G", [2], 1,
      DEV_PORTS, lambda: B.DeviceBlock(D.Rng),
      "Slot 12: SEED, VALUE (read steps the generator), PEEK. A 16-bit Galois LFSR with taps 0xB400.",
      DIG("in clk, in rst, in seed_we, in seed:16, in step, out value:16", lambda: _SmallRng(), GATES_MUX_FF,
          "16 D flip-flops and XOR gates."), slot=12),
    P(55, "sp_guard", "Stack guard", "G", [5], 2,
      DEV_PORTS + ", in commit, in rf_we, in rd:5, in rf_wd:32, out irq", lambda: B.IrqOut(D.SpGuard),
      "Slot 13: LIMIT, STATUS bit0 (sp went below LIMIT), MINSP (lowest sp seen). Watches every write "
      "to register x2 (sp). irq = STATUS bit0.",
      DIG("in clk, in rst, in sp_we, in sp:8, in limit:8, in clear, out minsp:8, out flag",
          lambda: _SmallSpGuard(), ARITH, "8-bit: a minimum register and two comparators."), slot=13),
    P(56, "class_stats", "Instruction-mix counters", "G", [4, 5], 1,
      DEV_PORTS + ", in commit, in is_load, in is_store, in is_branch, in taken, in is_jump",
      lambda: B.DeviceBlock(D.Stats),
      "Slot 14: LOADS, STORES, BRANCHES, TAKEN, JUMPS, CLEAR - counts of committed instructions by kind.",
      DIG("in clk, in rst, in commit, in is_load, in is_branch, in clear, out loads:8, out branches:8",
          lambda: _SmallStats(), GATES_MUX_FF, "Two 8-bit counters with enable and clear."), slot=14),
    P(57, "halt_ctrl", "Halt controller", "G", [4], 1,
      DEV_PORTS + ", in commit, in instr:32, out halted", B.HaltBlock,
      "Slot 15: HALT (any write stops the machine), CODE. A committed `j .` (0x0000006F) also halts.",
      DIG("in clk, in rst, in write_halt, in commit, in instr:32, out halted", lambda: _SmallHalt(), ARITH,
          "A sticky flip-flop and a 32-bit comparator."), slot=15),
    P(58, "bpred", "Branch predictor (2-bit counters)", "G", [4], 3,
      DEV_PORTS + ", in commit, in is_branch, in taken, in pc:32", lambda: B.DeviceBlock(D.Bpred),
      "Slot 16: BRANCHES, CORRECT, CLEAR. 16 two-bit saturating counters indexed by pc[5:2] predict "
      "each branch; the counts show how well a pipeline could guess.",
      DIG("in clk, in rst, in commit, in is_branch, in taken, in idx:2, out predict, out correct:8",
          lambda: _SmallBpred(), ARITH, "4 counters of 2 bits, the prediction multiplexer and a correct-count."),
      slot=16),
    P(59, "hazard_meter", "Pipeline hazard meter", "G", [4], 2,
      DEV_PORTS + ", in commit, in instr:32, in rf_we, in rd:5, in is_load", lambda: B.DeviceBlock(D.Hazard),
      "Slot 17: LOADUSE, RAW1, CLEAR. Counts instructions that read the register written by the "
      "instruction just before them (a pipeline would need forwarding or a stall).",
      DIG("in clk, in rst, in commit, in rd:5, in rf_we, in is_load, in rs1:5, in uses_rs1, in rs2:5, "
          "in uses_rs2, out raw:8, out loaduse:8", lambda: _SmallHazard(), ARITH,
          "A previous-rd register, comparators and two counters."), slot=17),
    P(60, "parity_unit", "Parity generator", "G", [2, 3], 1,
      DEV_PORTS, lambda: B.DeviceBlock(D.Parity),
      "Slot 18: DATA, PARITY (bit k = parity of byte k, bit 4 = parity of the word), ODD (bytes with "
      "odd parity).",
      DIG("in data:32, out parity:5, out odd:3", lambda i: _parity(i), ARITH,
          "XOR trees for each byte, then the totals."), slot=18),
    P(61, "text_screen", "Text screen", "G", [2, 6], 2,
      DEV_PORTS + ", in dbg_addr:6, out dbg_char:8", B.ScreenBlock,
      "Slot 19: a 4 x 16 character screen. CHAR (write at cursor and advance, newline goes to the next "
      "row), CURSOR, CLEAR, READ. dbg_addr/dbg_char let the test bench read the screen.",
      DIG("in clk, in rst, in put, in newline, in clear, out cursor:6", lambda: _SmallCursor(), ARITH,
          "The cursor logic: a 6-bit register, +1, next-row and wrap-around."), slot=19),
    P(62, "irq_latency", "Interrupt latency meter", "G", [4, 6], 1,
      DEV_PORTS + ", in irq_line, in trap_irq", lambda: B.DeviceBlock(D.IrqLat),
      "Slot 20: LAST, MAX, CLEAR, COUNT - how many cycles an enabled interrupt waits before it is taken.",
      DIG("in clk, in rst, in irq_line, in trap_irq, in clear, out last:8, out max:8", lambda: _SmallLat(),
          ARITH, "A counter, a LAST register and a MAX register with a comparator."), slot=20),
    P(63, "hw_stack", "Hardware stack", "G", [5], 2,
      DEV_PORTS, lambda: B.DeviceBlock(D.HwStack),
      "Slot 21: PUSH, POP (read removes), TOP, COUNT, STATUS (empty, full, overflow, underflow). "
      "8 entries: stack organisation in hardware.",
      DIG("in clk, in rst, in push, in pop, in d:4, out top:4, out count:3, out empty, out full",
          lambda: _SmallStack(), GATES_MUX_FF, "4 entries x 4 bits with a stack pointer."), slot=21),
    P(64, "code_conv", "Code converter (Gray, excess-3)", "G", [3], 1,
      DEV_PORTS, lambda: B.DeviceBlock(D.CodeConv),
      "Slot 22: VAL, GRAY, FROMGRAY, XS3 (excess-3 of the four decimal digits).",
      DIG("in v:8, in digit:4, out gray:8, out fromgray:8, out xs3:4", lambda i: _codeconv(i), GATES,
          "XOR gates for Gray code; an excess-3 digit from gates (K-maps)."), slot=22),
    P(65, "complement_unit", "Complement unit (r and r-1 complements)", "G", [3], 2,
      DEV_PORTS, lambda: B.DeviceBlock(D.Compl),
      "Slot 23: VAL, ONES, TWOS, SIGNMAG, NINES, TENS - binary and decimal complements of a value.",
      DIG("in v:8, in d:4, out ones:8, out twos:8, out nines:4", lambda i: _compl(i), GATES,
          "8-bit 1's and 2's complement from gates (incrementer), and a 9's-complement digit."), slot=23),
    P(66, "reset_ctrl", "Reset controller", "G", [1, 4], 1,
      "in clk, in btn, out rst", B.ResetCtrl,
      "Holds rst high for 4 clock cycles after power-on or after the reset button.",
      DIG("in clk, in btn, out rst", B.ResetCtrl, GATES_FF, "A 3-bit counter that stops at 4.")),
]


# --------------------------------------------- scaled models for Digital
def _mask_out(o, widths):
    return {k: (v & ((1 << widths[k]) - 1)) if k in widths else v for k, v in o.items()}


class _SmallRam(B.DataRam):
    def __init__(self):
        super().__init__(4)

    def clock(self, i):
        if i["we"]:
            self.m[i["addr"] % 4] = i["wdata"] & 0xFF


class _SmallCache:
    def __init__(self):
        self.reset()

    def reset(self):
        self.v = [0] * 4
        self.t = [0] * 4

    def clock(self, i):
        if i["rst"]:
            self.reset()
        elif i["access"]:
            k = (i["addr"] >> 2) & 3
            self.v[k], self.t[k] = 1, i["addr"] >> 4

    def outputs(self, i):
        k = (i["addr"] >> 2) & 3
        return {"hit": int(bool(i["access"] and self.v[k] and self.t[k] == i["addr"] >> 4))}


class _SmallCounts:
    def __init__(self):
        self.reset()

    def reset(self):
        self.h = self.m = 0

    def clock(self, i):
        if i["rst"] or i["clear"]:
            self.h = self.m = 0
        elif i["access"]:
            if i["hit"]: self.h = (self.h + 1) & 255
            else: self.m = (self.m + 1) & 255

    def outputs(self, i):
        return {"hits": self.h, "misses": self.m}


class _SmallCsr:
    def __init__(self):
        self.reset()

    def reset(self):
        self.mtvec = self.mie = self.mpie = 0

    def clock(self, i):
        if i["rst"]:
            self.reset()
        elif i["trap"]:
            self.mpie, self.mie = self.mie, 0
        elif i["mret"]:
            self.mie, self.mpie = self.mpie, 1
        else:
            if i["we"]:
                self.mtvec = i["wdata"]
            if i["set_mie"]:
                self.mie = 1

    def outputs(self, i):
        return {"mtvec": self.mtvec, "mie": self.mie, "mpie": self.mpie}


class _SmallUart:
    def __init__(self):
        self.reset()

    def reset(self):
        self.busy, self.acc = 0, 0

    def clock(self, i):
        if i["rst"]:
            self.reset()
        elif i["write"] and self.busy == 0:
            self.busy, self.acc = 4, 1
        else:
            self.acc = 0
            if self.busy:
                self.busy -= 1

    def outputs(self, i):
        return {"ready": int(self.busy == 0), "accept": self.acc}


class _SmallKbd:
    def __init__(self):
        self.reset()

    def reset(self):
        self.full, self.data = 0, 0

    def clock(self, i):
        if i["rst"]:
            self.reset()
            return
        popped = i["pop"]
        if popped:
            self.full = 0
        elif not self.full and i["ext_valid"]:
            self.full, self.data = 1, i["ext_char"]

    def outputs(self, i):
        return {"data": self.data if self.full else 0, "full": self.full,
                "take": int(not self.full and i["ext_valid"] and not i["pop"])}


class _SmallGpio:
    def __init__(self):
        self.reset()

    def reset(self):
        self.leds = 0

    def clock(self, i):
        if i["rst"]:
            self.leds = 0
        elif i["we"] and i["ridx"] == 0:
            self.leds = i["wdata"]

    def outputs(self, i):
        return {"rdata": {0: self.leds, 2: i["buttons"]}.get(i["ridx"], 0), "leds": self.leds}


def _irq_comb(i):
    a = i["lines"] & i["mask"]
    c = next((k for k in range(5) if a >> k & 1), 31)
    return {"irq": int(a != 0), "cause": c}


class _SmallTimer:
    def __init__(self):
        self.reset()

    def reset(self):
        self.c = self.m = 0

    def clock(self, i):
        if i["rst"]:
            self.reset()
            return
        hit = i["en"] and self.c == i["cmp"]
        if i["clr"]:
            self.m = 0
        elif hit:
            self.m = 1
        if i["load"]:
            self.c = i["d"]
        elif i["en"]:
            self.c = (self.c + 1) & 255

    def outputs(self, i):
        return {"count": self.c, "match": self.m}


class _SmallDma:
    def __init__(self):
        self.reset()

    def reset(self):
        self.busy = self.phase = self.done = 0
        self.n = 0

    def clock(self, i):
        if i["rst"]:
            self.reset()
            return
        if self.busy:
            if self.phase == 0:
                self.phase = 1
            else:
                self.phase = 0
                self.n = (self.n - 1) & 15
                if self.n == 0:
                    self.busy, self.done = 0, 1
        elif i["start"]:
            self.n = i["len"]
            if self.n:
                self.busy, self.phase, self.done = 1, 0, 0
            else:
                self.done = 1

    def outputs(self, i):
        return {"busy": self.busy, "phase": self.phase, "done": self.done}


class _SmallPerf:
    def __init__(self):
        self.reset()

    def reset(self):
        self.c = self.n = 0

    def clock(self, i):
        if i["rst"] or i["clear"]:
            self.reset()
            return
        self.c = (self.c + 1) & 255
        if i["commit"]:
            self.n = (self.n + 1) & 255

    def outputs(self, i):
        return {"cycle": self.c, "instret": self.n}


class _SmallMul:
    def __init__(self):
        self.reset()

    def reset(self):
        self.acc = self.mc = self.mp = self.k = 0

    def clock(self, i):
        if i["rst"]:
            self.reset()
            return
        if self.k:
            if self.mp & 1:
                self.acc = (self.acc + self.mc) & 255
            self.mc = (self.mc << 1) & 255
            self.mp >>= 1
            self.k -= 1
        elif i["start"]:
            self.acc, self.mc, self.mp, self.k = 0, i["a"], i["b"], 4

    def outputs(self, i):
        return {"result": self.acc, "busy": int(self.k != 0)}


def _simd_small(i):
    a, b = i["a"], i["b"]
    la, lb = [(a >> 4 * k) & 15 for k in range(2)], [(b >> 4 * k) & 15 for k in range(2)]
    return {"sum": sum(((x + y) & 15) << 4 * k for k, (x, y) in enumerate(zip(la, lb))),
            "max": sum(max(x, y) << 4 * k for k, (x, y) in enumerate(zip(la, lb)))}


class _SmallWdt:
    def __init__(self):
        self.reset()

    def reset(self):
        self.c = self.b = 0

    def clock(self, i):
        if i["rst"]:
            self.reset()
        elif i["kick"]:
            self.c = i["load"]
        elif i["en"]:
            if self.c == 0:
                self.b, self.c = 1, i["load"]
            else:
                self.c -= 1

    def outputs(self, i):
        return {"count": self.c, "bite": self.b}


class _SmallRng:
    def __init__(self):
        self.reset()

    def reset(self):
        self.x = 0xACE1

    def clock(self, i):
        if i["rst"]:
            self.reset()
        elif i["seed_we"]:
            self.x = i["seed"] or 0xACE1
        elif i["step"]:
            self.x = D.lfsr_step(self.x)

    def outputs(self, i):
        return {"value": self.x}


class _SmallSpGuard:
    def __init__(self):
        self.reset()

    def reset(self):
        self.m, self.f = 255, 0

    def clock(self, i):
        if i["rst"] or i["clear"]:
            self.reset()
        elif i["sp_we"]:
            self.m = min(self.m, i["sp"])
            if i["limit"] and i["sp"] < i["limit"]:
                self.f = 1

    def outputs(self, i):
        return {"minsp": self.m, "flag": self.f}


class _SmallStats:
    def __init__(self):
        self.reset()

    def reset(self):
        self.l = self.b = 0

    def clock(self, i):
        if i["rst"] or i["clear"]:
            self.reset()
        elif i["commit"]:
            self.l = (self.l + i["is_load"]) & 255
            self.b = (self.b + i["is_branch"]) & 255

    def outputs(self, i):
        return {"loads": self.l, "branches": self.b}


class _SmallHalt:
    def __init__(self):
        self.reset()

    def reset(self):
        self.h = 0

    def clock(self, i):
        if i["rst"]:
            self.h = 0
        elif i["write_halt"] or (i["commit"] and i["instr"] == 0x6F):
            self.h = 1

    def outputs(self, i):
        return {"halted": self.h}


class _SmallBpred:
    def __init__(self):
        self.reset()

    def reset(self):
        self.t = [1] * 4
        self.ok = 0

    def clock(self, i):
        if i["rst"]:
            self.reset()
        elif i["commit"] and i["is_branch"]:
            k = i["idx"]
            if (self.t[k] >= 2) == bool(i["taken"]):
                self.ok = (self.ok + 1) & 255
            self.t[k] = min(3, self.t[k] + 1) if i["taken"] else max(0, self.t[k] - 1)

    def outputs(self, i):
        return {"predict": int(self.t[i["idx"]] >= 2), "correct": self.ok}


class _SmallHazard:
    def __init__(self):
        self.reset()

    def reset(self):
        self.prd = self.pl = self.raw = self.lu = 0

    def clock(self, i):
        if i["rst"]:
            self.reset()
        elif i["commit"]:
            dep = self.prd != 0 and ((i["uses_rs1"] and i["rs1"] == self.prd) or (i["uses_rs2"] and i["rs2"] == self.prd))
            if dep:
                self.raw = (self.raw + 1) & 255
                if self.pl:
                    self.lu = (self.lu + 1) & 255
            self.prd = i["rd"] if i["rf_we"] else 0
            self.pl = i["is_load"]

    def outputs(self, i):
        return {"raw": self.raw, "loaduse": self.lu}


def _parity(i):
    d = i["data"]
    bits = [D.parity8(d >> 8 * k) for k in range(4)]
    return {"parity": sum(b << k for k, b in enumerate(bits)) | ((sum(bits) & 1) << 4), "odd": sum(bits)}


class _SmallCursor:
    def __init__(self):
        self.reset()

    def reset(self):
        self.c = 0

    def clock(self, i):
        if i["rst"] or i["clear"]:
            self.c = 0
        elif i["newline"]:
            self.c = ((self.c // 16) + 1) * 16 % 64
        elif i["put"]:
            self.c = (self.c + 1) % 64

    def outputs(self, i):
        return {"cursor": self.c}


class _SmallLat:
    def __init__(self):
        self.reset()

    def reset(self):
        self.l = self.m = self.c = 0

    def clock(self, i):
        if i["rst"] or i["clear"]:
            self.reset()
        elif i["trap_irq"]:
            self.l, self.m, self.c = self.c, max(self.m, self.c), 0
        elif i["irq_line"]:
            self.c = (self.c + 1) & 255

    def outputs(self, i):
        return {"last": self.l, "max": self.m}


class _SmallStack:
    def __init__(self):
        self.reset()

    def reset(self):
        self.s = []

    def clock(self, i):
        if i["rst"]:
            self.reset()
        elif i["push"] and not i["pop"]:
            if len(self.s) < 4:
                self.s.append(i["d"])
        elif i["pop"] and not i["push"]:
            if self.s:
                self.s.pop()

    def outputs(self, i):
        return {"top": self.s[-1] if self.s else 0, "count": len(self.s),
                "empty": int(not self.s), "full": int(len(self.s) == 4)}


def _codeconv(i):
    v, d = i["v"], i["digit"]
    return {"gray": v ^ (v >> 1), "fromgray": D.from_gray(v), "xs3": (d + 3) & 15 if d <= 9 else 0}


def _compl(i):
    v, d = i["v"], i["d"]
    return {"ones": ~v & 255, "twos": -v & 255, "nines": 9 - d if d <= 9 else 0}


BY_ID = {p["id"]: p for p in PACKAGES}
assert len(PACKAGES) == 66 and sorted(BY_ID) == list(range(1, 67))
assert all(p["hw"] + p["prog"] == 4 for p in PACKAGES)
