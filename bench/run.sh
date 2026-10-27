#!/bin/bash
# Benchmark: one agent (claude alone) vs sealed-council (3 seats, blind ranks, host merge).
# Usage: bench/run.sh [task-file...]   (default: all of bench/tasks/*.md)
# Writes bench/results/<task>/{single.md,council.md,A.md,B.md,C.md,rank-*.md,reveal.txt}.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
sc="$here/../bin/sealed-council"
export SC_HOME="${SC_HOME:-$HOME/.sealed-council-bench}"
cd "$here"
[ $# -gt 0 ] || set -- tasks/*.md

host_prompt() { # round dir
  printf '%s\n\n' "You are the host of a council. Below are a brief, three anonymous answers (A, B, C) and peer rankings. Write the single best final answer to the brief for the user: keep what is right in each answer, drop what is wrong, and fix any error a reviewer found. Follow the brief's format and word limit. Output only the final answer. Do not mention A, B, C, rankings, reviewers or a council."
  printf 'BRIEF:\n%s\n\n' "$(cat "$1/brief.md")"
  for l in A B C; do [ -f "$1/$l.md" ] && printf '=== %s ===\n%s\n\n' "$l" "$(cat "$1/$l.md")"; done
  for f in "$1"/rank-*.md; do [ -f "$f" ] && printf '=== review ===\n%s\n\n' "$(cat "$f")"; done
}

for t in "$@"; do
  name=$(basename "$t" .md); out="results/$name"
  [ -s "$out/council.md" ] && { echo "skip $name"; continue; }
  mkdir -p "$out"; start=$(date +%s)
  r=$("$sc" new "$t")
  "$sc" ask "$r" >/dev/null 2>&1 || true
  "$sc" seal "$r" >/dev/null
  "$sc" rank "$r" >/dev/null 2>&1 || true
  host_prompt "$r" | (cd "$(mktemp -d)" && claude -p --tools "" ) > "$r/verdict.md"
  cp "$SC_HOME/rounds/$(basename "$r")/answers/claude.md" "$out/single.md"
  cp "$r/verdict.md" "$out/council.md"
  cp "$r"/[ABC].md "$out/"
  "$sc" reveal "$r" > "$out/reveal.txt"
  cp "$r"/rank-*.md "$out/" 2>/dev/null || true
  echo "$name done in $(( $(date +%s) - start ))s"
done
