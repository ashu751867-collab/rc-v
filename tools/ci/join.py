"""Handle a "Join RC-V" issue (run by .github/workflows/join.yml).

    python tools/ci/join.py members.json join_codes.json  > result.json

Reads ISSUE_BODY, ISSUE_USER, ISSUE_NUMBER, REPO from the environment.
Join codes are never stored in the repository, only salted SHA-256 hashes.
"""
import datetime
import hashlib
import json
import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from rcv.packages import BY_ID  # noqa: E402

CODE = re.compile(r"\b([A-HJ-NP-Z2-9]{4})-?([A-HJ-NP-Z2-9]{4})-?([A-HJ-NP-Z2-9]{4})\b")


def code_hash(salt, code):
    return hashlib.sha256((salt + code).encode()).hexdigest()


def main(members_path, codes_path):
    body = os.environ.get("ISSUE_BODY", "") or ""
    user = os.environ["ISSUE_USER"]
    number = os.environ.get("ISSUE_NUMBER", "")
    repo = os.environ.get("REPO", "")
    members = json.loads(Path(members_path).read_text() or "{}")
    codes = json.loads(Path(codes_path).read_text())
    res = {"ok": False, "message": "", "title": "", "label": ""}

    def done(msg):
        res["message"] = msg
        print(json.dumps(res))

    m = CODE.search(re.sub(r"\s*-\s*", "-", body.upper()))     # tolerate "ABCD - EFGH - JKLM"
    if not m:
        return done(f"@{user} I could not find a join code in your issue. It looks like `ABCD-EFGH-JKLM` "
                    "(three groups of four letters/digits). Edit the issue and paste your code.")
    code = "-".join(m.groups())
    pkg = codes["hashes"].get(code_hash(codes["salt"], code))
    if not pkg:
        return done(f"@{user} that join code is not valid. Check it against the slip your teacher gave you "
                    "(the letters I, O and the digits 0, 1 are never used) and edit the issue.")
    pkg = int(pkg)
    mine = [int(k) for k, v in members.items() if v["github"].lower() == user.lower()]
    if pkg in mine:
        res.update(ok=True)
    elif mine:
        return done(f"@{user} you have already joined as P{mine[0]:02d}. Each student builds one package. "
                    "If you think this is a mistake, tell your teacher.")
    elif str(pkg) in members:
        return done(f"@{user} package P{pkg:02d} has already been taken by another account. "
                    "Tell your teacher; do not share your code with anyone.")
    else:
        members[str(pkg)] = {"github": user, "issue": int(number or 0),
                             "joined": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M")}
        Path(members_path).write_text(json.dumps(dict(sorted(members.items(), key=lambda kv: int(kv[0]))), indent=1))
        res.update(ok=True)
    p = BY_ID[pkg]
    folder = f"packages/P{pkg:02d}-{p['slug']}"
    res["title"] = f"P{pkg:02d} {p['title']} - @{user}"
    res["label"] = f"P{pkg:02d}"
    url = f"https://github.com/{repo}/tree/main/{folder}"
    return done(
        f"Welcome to RC-V, @{user}! 🎉\n\n"
        f"You are building **P{pkg:02d} - {p['title']}** ({folder}).\n\n"
        f"1. Read your task: [{folder}/README.md]({url}/README.md)\n"
        f"2. Fork this repository (button at the top right), then follow docs/WORKFLOW.md to hand in "
        f"your files with a pull request.\n"
        f"3. Keep this issue open: it is your notebook for the project. Ask questions here, and mention "
        f"your review partners when you need them.\n\n"
        f"Your package is now linked to your GitHub account, so only you can change its files.")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
