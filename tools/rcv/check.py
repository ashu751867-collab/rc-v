"""Check one package (what the GitHub checker runs on every pull request).

    python -m rcv.check 17            # check packages/P17-*
    python -m rcv.check 17 --json out.json

Parts that are still the untouched starter file count as "not started",
not as failures. Needs: Java + Digital.jar (RCV_DIGITAL_JAR) for the circuit,
iverilog (or RCV_DOCKER=1) for the Verilog.
"""
import json
import os
import re
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

from .gen import (PKG_DIR, digital_stub, dossier, folder, module_name, pid, program_stub, verilog_stub,
                  INSTR_TRACE, neighbours_of)
from .packages import BY_ID
from .progrun import label_problems, run
from .soc import sh
from .vectors import parse_ports

WIRING = {"Splitter", "Tunnel", "Const", "Ground", "VDD", "Text", "In", "Out", "Clock", "Testcase",
          "Probe", "LED", "Rectangle", "Button", "DipSwitch", "PullDown", "PullUp"}
GATES = {"And", "Or", "Not", "NAnd", "NOr", "XOr", "XNOr"}
MUX = {"Multiplexer", "Demultiplexer", "Decoder", "PriorityEncoder", "BitSelector"}
FF = {"D_FF", "JK_FF", "T_FF", "RS_FF", "D_FF_AS", "JK_FF_AS", "RS_FF_AS"}
ARITH = {"Add", "Sub", "Comparator", "Neg", "BitExtender"}
ALLOWED = {
    "wiring": WIRING, "gates": WIRING | GATES, "gates+mux": WIRING | GATES | MUX,
    "gates+ff": WIRING | GATES | FF, "gates+mux+ff": WIRING | GATES | MUX | FF,
    "gates+mux+ff+arith": WIRING | GATES | MUX | FF | ARITH, "gates+mux+rom": WIRING | GATES | MUX | {"ROM"},
}


def same_as_starter(path, starter_text):
    return path.read_text(encoding="utf-8", errors="replace").strip() == starter_text.strip()


# ------------------------------------------------------------------ Digital
def dig_elements(path, seen=None):
    """All element names used in a .dig file and its sub-circuits in the same folder."""
    seen = seen or set()
    if path in seen:
        return [], []
    seen.add(path)
    root = ET.parse(path).getroot()
    names, problems = [], []
    for ve in root.iter("visualElement"):
        n = ve.findtext("elementName")
        if n.endswith(".dig"):
            sub = path.parent / n
            if not sub.exists():
                problems.append(f"sub-circuit {n} is missing (it must be in your package folder)")
                continue
            sn, sp = dig_elements(sub, seen)
            names += sn
            problems += sp
        else:
            names.append(n)
    return names, problems


def dig_pins(path):
    root = ET.parse(path).getroot()
    pins = {}
    for ve in root.iter("visualElement"):
        n = ve.findtext("elementName")
        if n in ("In", "Out", "Clock"):
            attrs = {}
            for e in ve.iter("entry"):
                kids = list(e)
                if len(kids) == 2:
                    attrs[kids[0].text] = kids[1].text
            pins[attrs.get("Label", "?")] = ("out" if n == "Out" else "in", int(attrs.get("Bits", 1)))
    return pins


def check_digital(p, f, jar):
    path = f / f"{pid(p)}.dig"
    if not path.exists():
        return "fail", [f"{path.name} is missing"]
    tests = (f / "tests" / f"{pid(p)}_tests.dig")
    try:
        names, problems = dig_elements(path)
        pins = dig_pins(path)
    except ET.ParseError as e:
        return "fail", [f"{path.name} is not a valid Digital file: {e}"]
    logic = [n for n in names if n not in WIRING]
    wires = len(list(ET.parse(path).getroot().iter("wire")))
    if not logic and (p["dig"]["parts"] != "wiring" or wires == 0):
        return "not started", ["no parts placed yet"]
    want = {n: (d, w) for d, n, w in parse_ports(p["dig"]["ports"])}
    for n, (d, w) in want.items():
        if n not in pins:
            problems.append(f"pin '{n}' is missing or renamed")
        elif pins[n] != (d, w):
            problems.append(f"pin '{n}' should be {'an input' if d == 'in' else 'an output'} of {w} bit(s)")
    for n in pins:
        if n not in want:
            problems.append(f"extra pin '{n}' (use Tunnels instead of extra inputs/outputs)")
    allowed = ALLOWED[p["dig"]["parts"]]
    bad = sorted(set(n for n in names if n not in allowed))
    if bad:
        problems.append(f"parts not allowed in this package: {', '.join(bad)}")
    if not jar:
        problems.append("Digital.jar not available: tests not run")
        return "fail", problems
    r = subprocess.run(["java", "-Djava.awt.headless=true", "-cp", jar, "CLI", "test", "-circ", str(path),
                        "-tests", str(tests), "-verbose"], capture_output=True, text=True, cwd=f)
    out = (r.stdout + r.stderr).strip()
    if r.returncode != 0 or "passed" not in out:
        lines = [l for l in out.splitlines() if l.strip() and "java.util.prefs" not in l
                 and not l.startswith("INFO:")][:12]
        problems.append("tests failed:\n" + "\n".join("    " + l for l in lines))
    return ("pass" if not problems else "fail"), problems


# ------------------------------------------------------------------ Verilog
def check_verilog(p, f):
    path = f / f"{module_name(p)}.v"
    if not path.exists():
        return "fail", [f"{path.name} is missing"]
    if same_as_starter(path, verilog_stub(p)):
        return "not started", ["still the starter file"]
    text = path.read_text(encoding="utf-8", errors="replace")
    problems = []
    mods = re.findall(r"^\s*module\s+(\w+)", text, re.M)
    if mods != [module_name(p)]:
        problems.append(f"the file must contain exactly one module, named {module_name(p)} (found: {', '.join(mods) or 'none'})")
    other = [m for m in re.findall(r"^\s*(p\d\d_\w+)\s+(?:#\s*\(|\w+\s*\()", text, re.M) if m != module_name(p)]
    if other:
        problems.append(f"do not instantiate other packages' modules ({', '.join(other)})")
    with tempfile.TemporaryDirectory() as d:
        d = Path(d)
        (d / "dut.v").write_text(text, encoding="utf-8")
        (d / "tests").mkdir()
        for t in (f / "tests").iterdir():
            if t.is_file():
                (d / t.name).write_bytes(t.read_bytes())
                (d / "tests" / t.name).write_bytes(t.read_bytes())
        tb = f"tb_{module_name(p)}.v"
        r = sh(f"iverilog -g2012 -o sim {tb} dut.v && vvp -n sim", d)
        out = (r.stdout + r.stderr).strip()
        if "RESULT PASS" not in out:
            lines = [l for l in out.splitlines() if l.strip() and "$finish" not in l][:14]
            problems.append("test bench failed:\n" + "\n".join("    " + l for l in lines))
    return ("pass" if not problems else "fail"), problems


# ------------------------------------------------------------------ program
def check_program(p, f):
    n = p["id"]
    path = f / f"p{n:02d}.s"
    if not path.exists():
        return "fail", [f"{path.name} is missing"]
    if same_as_starter(path, program_stub(p)):
        return "not started", ["still the starter file"]
    text = path.read_text(encoding="utf-8", errors="replace")
    problems = []
    bad = label_problems(n, None, text)
    if bad:
        problems.append(f"labels must start with p{n:02d}_: {', '.join(bad)}")
    tests = sorted((f / "tests" / "program").glob("*.in"))
    if not tests:
        problems.append("no program tests yet (ask your teacher)")
    for t in tests:
        exp = t.with_suffix(".out").read_text(encoding="utf-8")
        m, out = run(n, text, t.read_text(encoding="utf-8"))
        if m is None:
            problems.append("assembly errors:\n" + "\n".join("    " + e for e in out[:10]))
            break
        if out.rstrip() != exp.rstrip():
            problems.append(f"{t.name}: output differs\n    expected: {exp.rstrip()[:300]!r}\n    got:      {out.rstrip()[:300]!r}")
    return ("pass" if not problems else "fail"), problems


# ------------------------------------------------------------------ dossier
def check_dossier(p, f):
    path = f / "DOSSIER.md"
    if not path.exists():
        return "fail", ["DOSSIER.md is missing"]
    text = path.read_text(encoding="utf-8", errors="replace")
    tmpl = dossier(p, INSTR_TRACE[(p["id"] - 1) % len(INSTR_TRACE)], neighbours_of(p))
    if text.strip() == tmpl.strip():
        return "not started", ["still the template"]
    heads = re.findall(r"^## (\S+)", tmpl, re.M)
    sections = re.split(r"^## ", text, flags=re.M)
    got = {s.split()[0]: s for s in sections[1:] if s.strip()}
    tsec = {s.split()[0]: s for s in re.split(r"^## ", tmpl, flags=re.M)[1:]}
    empty = []
    for h in heads:
        if h not in got:
            empty.append(h)
            continue
        extra = set(re.findall(r"\w+", got[h].lower())) - set(re.findall(r"\w+", tsec[h].lower()))
        # E4 is a checklist; E2 (reviews) depends on partners' pull requests, so it is
        # marked at the end as teamwork and does not block a merge
        if len(extra) < 8 and h not in ("E2", "E4"):
            empty.append(h)
    if empty:
        return "fail", [f"sections not answered yet: {', '.join(empty)}"]
    return "pass", []


def check(n, jar=None):
    p = BY_ID[n]
    f = folder(p)
    jar = jar or os.environ.get("RCV_DIGITAL_JAR")
    res = {}
    for name, fn in (("digital", lambda: check_digital(p, f, jar)), ("verilog", lambda: check_verilog(p, f)),
                     ("program", lambda: check_program(p, f)), ("dossier", lambda: check_dossier(p, f))):
        try:
            res[name] = fn()
        except Exception as e:      # a broken file must not crash the checker
            res[name] = ("fail", [f"checker could not read it: {e}"])
    return res


ICON = {"pass": "✅", "fail": "❌", "not started": "⬜"}


def report_md(n, res):
    p = BY_ID[n]
    lines = [f"### {pid(p)} {p['title']}", "", "| Part | Result |", "|---|---|"]
    for k, (st, _) in res.items():
        lines.append(f"| {k} | {ICON[st]} {st} |")
    for k, (st, probs) in res.items():
        if probs and st != "not started":
            lines += ["", f"**{k}**", "```", *probs, "```"]
    return "\n".join(lines) + "\n"


def main(argv=None):
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("n", type=int, nargs="+")
    ap.add_argument("--json")
    ap.add_argument("--md")
    a = ap.parse_args(argv)
    allres, md, failed = {}, [], False
    for n in a.n:
        res = check(n)
        allres[n] = {k: {"status": s, "problems": pr} for k, (s, pr) in res.items()}
        md.append(report_md(n, res))
        failed |= any(s == "fail" for s, _ in res.values())
    text = "\n".join(md)
    print(text)
    if a.md:
        Path(a.md).write_text(text, encoding="utf-8")
    if a.json:
        Path(a.json).write_text(json.dumps(allres, indent=1), encoding="utf-8")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
