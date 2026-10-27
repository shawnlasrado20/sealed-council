#!/usr/bin/env python3
"""Build the blind grading page from bench/results.

Each task shows single.md and council.md as X and Y in random order.
The key (which letter is the council) goes to $SC_HOME/grade-key.json, never into the page.
Usage: bench/make_grade_page.py <out.html>
"""
import json, os, random, sys
from pathlib import Path

here = Path(__file__).resolve().parent
home = Path(os.environ.get("SC_HOME", Path.home() / ".sealed-council-bench"))
tasks, key = [], {}
for t in sorted((here / "tasks").glob("*.md")):
    r = here / "results" / t.stem
    if not (r / "council.md").is_file():
        sys.exit(f"missing {r}/council.md")
    pair = [("single", (r / "single.md").read_text()), ("council", (r / "council.md").read_text())]
    random.shuffle(pair)
    key[t.stem] = {"X": pair[0][0], "Y": pair[1][0]}
    tasks.append({"id": t.stem, "brief": t.read_text(), "X": pair[0][1], "Y": pair[1][1]})

home.mkdir(parents=True, exist_ok=True)
(home / "grade-key.json").write_text(json.dumps(key, indent=1))
data = json.dumps(tasks).replace("</", "<\\/")
html = (here / "grade_template.html").read_text().replace("__DATA__", data)
Path(sys.argv[1]).write_text(html)
print(f"{len(tasks)} tasks, key in {home}/grade-key.json")
