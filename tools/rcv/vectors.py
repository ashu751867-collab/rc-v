"""Test-vector generation for the package blocks (Digital and Verilog)."""
import random

from . import spec
from .asm import assemble


def parse_ports(s):
    out = []
    for part in s.split(","):
        d, rest = part.split()
        if ":" in rest:
            n, w = rest.split(":")
            out.append((d, n, int(w)))
        else:
            out.append((d, rest, 1))
    return out


_INSTR_POOL = None


def instr_pool():
    """Valid RC-V instructions plus near-misses and random words."""
    global _INSTR_POOL
    if _INSTR_POOL is None:
        src = """
        lui a0, 0x12345
        auipc t1, 1
        jal ra, 8
        jalr ra, 4(t0)
        beq a0, a1, 8
        bne t0, zero, -8
        blt s0, s1, 16
        bge a2, a3, -16
        bltu a4, a5, 12
        bgeu a6, a7, -4
        lb a0, 3(sp)
        lbu t2, -1(s0)
        lw ra, 12(sp)
        sb a1, 7(t1)
        sw s2, -20(sp)
        addi sp, sp, -16
        slti t0, t1, -5
        sltiu t0, t1, 5
        xori a0, a0, -1
        ori a1, a2, 0x7f
        andi a3, a4, 15
        slli a0, a0, 3
        srli a1, a1, 31
        srai a2, a2, 7
        add a0, a1, a2
        sub t0, t1, t2
        sll s0, s1, s2
        slt s3, s4, s5
        sltu s6, s7, s8
        xor s9, s10, s11
        srl t3, t4, t5
        sra t6, a0, a1
        or a2, a3, a4
        and a5, a6, a7
        ecall
        mret
        csrrw t0, mtvec, t1
        csrrs a0, mstatus, zero
        csrrc a1, mscratch, a2
        nop
        """
        res = assemble([("pool", src)])
        good = [w for _, ws, _, _ in res["listing"] for w in ws]
        bad = [0x00000000, 0xFFFFFFFF, 0x00001003, 0x00003023, 0x0000106F & 0xFFFF8FFF | 0x1000,
               0x00002063, 0x00003063, 0x40001013, 0x40002033, 0x02000033, 0x00100073, 0x00004073,
               0x0000000F, 0x00001067, 0x00005003, 0x00001023, 0x0000007F, 0x10500073]
        _INSTR_POOL = (good, bad)
    return _INSTR_POOL


def rand_value(rng, w, override=None):
    if override is not None:
        if isinstance(override, list):
            return rng.choice(override)
        if override == "instr":
            good, bad = instr_pool()
            r = rng.random()
            if r < 0.6:
                return rng.choice(good)
            if r < 0.85:
                return rng.choice(bad)
            return rng.getrandbits(32)
        if override == "addr":
            base = rng.choice([spec.ROM_BASE, spec.RAM_BASE, spec.IO_BASE, 0x00004000, 0x00014000,
                               0x00020800, 0x00030000, 0xFFFF0000, 0x00008000])
            return (base + rng.choice([0, 4, 64, 0x3FC, 0x7FC, rng.getrandbits(14)])) & 0xFFFFFFFF
    m = (1 << w) - 1
    r = rng.random()
    if w == 1:
        return rng.getrandbits(1)
    if r < 0.08:
        return 0
    if r < 0.14:
        return m
    if r < 0.20:
        return 1 << (w - 1)
    if r < 0.25:
        return m >> 1
    if r < 0.45 and w > 4:
        return rng.getrandbits(min(w, 5))
    return rng.getrandbits(w)


def gen_inputs(rng, ins, gen):
    v = {}
    for d, n, w in ins:
        v[n] = rand_value(rng, w, gen.get(n))
    if "_onehot" in gen:
        names = gen["_onehot"]
        for n in names:
            v[n] = 0
        v[rng.choice(names)] = 1
    if "_onehot_opt" in gen:
        names = gen["_onehot_opt"]
        for n in names:
            v[n] = 0
        k = rng.randrange(len(names) + 1)
        if k < len(names):
            v[names[k]] = 1
    if "_same_often" in gen:
        a, b = gen["_same_often"]
        if rng.random() < 0.6:
            v[b] = v[a]
    return v


DEVICE_REGS = {p: regs for _s, (_n, p, regs) in spec.DEVICES.items()}


def device_inputs(rng, ins, pkg_id, prev):
    """Bus-cycle stimulus for a device: accesses biased to its real registers."""
    v = {}
    regs = list(DEVICE_REGS.get(pkg_id, {}).values()) or [0, 1, 2]
    for d, n, w in ins:
        if n in ("clk",):
            continue
        v[n] = rand_value(rng, w)
    v["rst"] = 0
    v["sel"] = int(rng.random() < 0.55)
    kind = rng.random()
    v["we"] = int(v["sel"] and kind < 0.5)
    v["re"] = int(v["sel"] and not v["we"])
    v["ridx"] = rng.choice(regs + [regs[0], spec.ID_REG]) if rng.random() < 0.95 else rng.getrandbits(4)
    v["wdata"] = rng.choice([rng.getrandbits(32), rng.getrandbits(4), rng.getrandbits(8),
                             1, 3, 0, rng.getrandbits(16)])
    if pkg_id == 48:          # DMA: short transfers into RAM
        if v["ridx"] in (0, 1):
            v["wdata"] = spec.RAM_BASE + 4 * rng.getrandbits(6)
        if v["ridx"] == 2:
            v["wdata"] = rng.choice([0, 1, 2, 3])
    if pkg_id == 46 and v["ridx"] == 1:
        v["wdata"] = rng.getrandbits(4)
    if pkg_id == 53 and v["ridx"] == 0:
        v["wdata"] = rng.getrandbits(3)
    if pkg_id == 55 and "rd" in v:
        v["rd"] = rng.choice([2, 2, 1, 8])
        v["rf_wd"] = rng.choice([0x13FF0, 0x13F00, 0x13000, 0x10100])
        if v["ridx"] == 0:
            v["wdata"] = rng.choice([0x13800, 0, 0x13F80])
    if pkg_id in (56, 59, 57) and "instr" in v:
        v["instr"] = rand_value(rng, 32, "instr") if rng.random() < 0.9 else 0x6F
    if pkg_id == 58 and "pc" in v:
        v["pc"] = rng.choice([0x40, 0x44, 0x80, 0x48, rng.getrandbits(8) & ~3])
    if pkg_id == 61 and v["ridx"] == 0 and rng.random() < 0.15:
        v["wdata"] = 10
    if pkg_id == 42:
        v["ext_char"] = rng.choice([65, 66, 10, 48, 122])
    return v


class Rows:
    def __init__(self, ins, outs, clocked):
        self.ins, self.outs, self.clocked, self.rows = ins, outs, clocked, []
        self.pre = []   # devices: rdata expected BEFORE the clock edge (it must be combinational)


def make_rows(pkg, variant, seed, n=None):
    """variant 'v' = Verilog (full size), 'd' = Digital (scaled)."""
    rng = random.Random(seed * 1000 + pkg["id"] * 7 + (1 if variant == "d" else 0))
    if variant == "v":
        ports, model, gen = parse_ports(pkg["ports"]), pkg["model"], pkg["gen"]
    else:
        dg = pkg["dig"]
        ports, model, gen = parse_ports(dg["ports"]), dg["model"], {**pkg["gen"], **dg["gen"]}
    ins = [p for p in ports if p[0] == "in"]
    outs = [p for p in ports if p[0] == "out"]
    clocked = any(n == "clk" for _, n, _ in ins)
    R = Rows(ins, outs, clocked)
    is_device = pkg.get("slot") is not None and variant == "v"
    if not clocked:
        widths = sum(w for _, _, w in ins)
        exhaustive = widths <= 10 and not gen
        if exhaustive:
            import itertools
            for vals in itertools.product(*[range(1 << w) for _, _, w in ins]):
                i = {n: x for (_, n, _), x in zip(ins, vals)}
                R.rows.append((i, model(i)))
        else:
            for _ in range(n or 160):
                i = gen_inputs(rng, ins, gen)
                R.rows.append((i, model(i)))
        return R
    blk = model()
    names = [n for _, n, _ in ins]
    steps = n or (260 if is_device else 160)
    prev = {}
    for k in range(steps):
        if is_device:
            i = device_inputs(rng, ins, pkg["id"], prev)
        else:
            i = gen_inputs(rng, ins, gen)
            if "rst" in names:
                i["rst"] = int(rng.random() < 0.03)
        if k == 0 and "rst" in names:
            i["rst"] = 1
        if k == 0 and "btn" in names:
            i["btn"] = 1
        if "btn" in names and k > 0:
            i["btn"] = int(rng.random() < 0.05)
        i["clk"] = "C"
        if is_device:
            # nothing is known before the first reset edge, so row 1 has no before-edge check
            R.pre.append(None if k == 0 else blk.outputs(i).get("rdata"))
        blk.clock(i)
        R.rows.append((i, blk.outputs(i)))
        prev = i
    return R
