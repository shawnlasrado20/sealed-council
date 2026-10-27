#!/bin/bash
# Blind AI judging: claude and codex each compare single vs council for every task, in both orders.
# The judges see only "Answer 1" and "Answer 2"; they are not told a council exists.
# Usage: bench/judge.sh   Writes bench/judged/<task>.<judge>.<order>.txt (order: sc = single first, cs = council first).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here"; mkdir -p judged

prompt() { # task first second
  printf '%s\n\n' "You are grading two answers to the same question. Judge which answer better serves the person who asked: correctness first, then completeness on what matters, then clarity. Length is not a virtue. Reply with the first line exactly 'WINNER: 1', 'WINNER: 2' or 'WINNER: TIE', then one sentence on why."
  printf 'QUESTION:\n%s\n\n=== Answer 1 ===\n%s\n\n=== Answer 2 ===\n%s\n' "$(cat "tasks/$1.md")" "$(cat "$2")" "$(cat "$3")"
}

judge() { # task judge order
  local t=$1 j=$2 o=$3 out="judged/$1.$2.$3.txt" a b
  [ -s "$out" ] && return
  if [ "$o" = sc ]; then a=results/$t/single.md; b=results/$t/council.md; else a=results/$t/council.md; b=results/$t/single.md; fi
  local d; d=$(mktemp -d)
  if [ "$j" = claude ]; then
    prompt "$t" "$a" "$b" | (cd "$d" && claude -p --tools "") > "$out"
  else
    prompt "$t" "$a" "$b" | codex exec --sandbox read-only --skip-git-repo-check -C "$d" -o "$here/$out" - >/dev/null 2>&1
  fi
  echo "$t $j $o: $(head -1 "$out")"
}
if [ "${1:-}" = --one ]; then judge "$2" "$3" "$4"; exit; fi
for t in tasks/*.md; do n=$(basename "$t" .md); for j in claude codex; do for o in sc cs; do echo "$n $j $o"; done; done; done \
  | xargs -P4 -n3 "$here/judge.sh" --one
