#!/usr/bin/env python3
"""Score bench/judged: 4 votes per task (2 judges x 2 orders). Council +1, single -1, tie 0.
Task goes to whoever has the positive sum; 0 is a tie. Prints a markdown table."""
import re
from pathlib import Path

here = Path(__file__).resolve().parent
first = {"sc": "single", "cs": "council"}
second = {"sc": "council", "cs": "single"}
rows, wins = [], {"council": 0, "single": 0, "tie": 0}
for t in sorted(p.stem for p in (here / "tasks").glob("*.md")):
    votes, cells = 0, []
    for j in ("claude", "codex"):
        picks = []
        for o in ("sc", "cs"):
            f = here / "judged" / f"{t}.{j}.{o}.txt"
            m = re.search(r"WINNER:\s*\**\s*(1|2|TIE)", f.read_text() if f.exists() else "", re.I)
            w = {"1": first[o], "2": second[o]}.get(m.group(1).upper(), "tie") if m else "missing"
            votes += {"council": 1, "single": -1}.get(w, 0)
            picks.append(w)
        cells.append(" / ".join(picks))
    res = "council" if votes > 0 else "single" if votes < 0 else "tie"
    wins[res] += 1
    rows.append(f"| {t} | {cells[0]} | {cells[1]} | {res} |")
print("| Task | Claude judge (both orders) | Codex judge (both orders) | Result |")
print("| --- | --- | --- | --- |")
print("\n".join(rows))
print(f"\nCouncil {wins['council']}, single {wins['single']}, tie {wins['tie']} (of {len(rows)})")
