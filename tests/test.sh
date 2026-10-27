#!/bin/bash
# Plain bash tests. No tmux, no real CLIs.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SC="$ROOT/bin/sealed-council"
failed=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; failed=1; }

if bash -n "$SC"; then pass "bash -n bin/sealed-council"; else fail "bash -n bin/sealed-council"; fi
lines=$(wc -l < "$SC" | tr -d ' ')
if [ "$lines" -lt 300 ]; then pass "script under 300 lines ($lines)"; else fail "script is $lines lines (cap 300)"; fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
proj="$tmp/proj"
mkdir -p "$proj"
cd "$proj"
export SC_HOME="$tmp/sc-home"
export STUB_LOG="$tmp/stub-log"
mkdir -p "$STUB_LOG" "$SC_HOME"

write_stub() {
  local dest=$1 body=$2
  mkdir -p "$(dirname "$dest")"
  cat > "$dest" <<EOF
#!/bin/bash
name=\$(basename "\$0")
mkdir -p "\$STUB_LOG"
out=""
args=("\$@")
i=0
while [ \$i -lt \$# ]; do
  a=\${args[\$i]}
  if [ "\$a" = -o ] || [ "\$a" = --output-last-message ]; then
    i=\$((i + 1)); out=\${args[\$i]}
  fi
  i=\$((i + 1))
done
printf '%s\n' "\$PWD" > "\$STUB_LOG/\$name.pwd"
: > "\$STUB_LOG/\$name.prompt"
if [ ! -t 0 ]; then cat > "\$STUB_LOG/\$name.prompt"; fi
if [ ! -s "\$STUB_LOG/\$name.prompt" ]; then printf '%s\n' "\$*" > "\$STUB_LOG/\$name.prompt"; fi
$body
EOF
  chmod +x "$dest"
}

ok="$tmp/ok"
emit='if grep -q identity-masked "$STUB_LOG/$name.prompt" 2>/dev/null; then
  off=$(sed -n "s/.*RANK: \([A-Z >]*\) (only.*/\1/p" "$STUB_LOG/$name.prompt" | head -1)
  text="RANK: $off
why"
fi; if [ -n "$out" ]; then printf "%s\n" "$text" >"$out"; else printf "%s\n" "$text"; fi'
write_stub "$ok/claude" "text=\"I am Claude\"; $emit"
write_stub "$ok/codex" "text=\"codex answer\"; $emit"
write_stub "$ok/agent" "text=\"agent answer\"; $emit"

slow="$tmp/slow"
write_stub "$slow/claude" 'sleep 10; text="slow"; if [ -n "$out" ]; then printf "%s\n" "$text" >"$out"; else printf "%s\n" "$text"; fi'

failstub="$tmp/fail"
write_stub "$failstub/claude" 'exit 3'
write_stub "$failstub/codex" 'exit 3'
write_stub "$failstub/agent" 'exit 3'
failone="$tmp/failone"
write_stub "$failone/claude" 'exit 3'
boom="$tmp/boom"
write_stub "$boom/claude" 'echo boom-err >&2; exit 3'
dup="$tmp/dup"
write_stub "$dup/claude" 'off=$(sed -n "s/.*RANK: \([A-Z >]*\) (only.*/\1/p" "$STUB_LOG/$name.prompt" | head -1); first=$(echo $off | awk "{print \$1}"); text="RANK: $first > $first
x"; if [ -n "$out" ]; then printf "%s\n" "$text" >"$out"; else printf "%s\n" "$text"; fi'
unk="$tmp/unk"
write_stub "$unk/claude" 'text="RANK: Z > Y
x"; if [ -n "$out" ]; then printf "%s\n" "$text" >"$out"; else printf "%s\n" "$text"; fi'
ownbad="$tmp/ownbad"
write_stub "$ownbad/claude" 'off=$(sed -n "s/.*RANK: \([A-Z >]*\) (only.*/\1/p" "$STUB_LOG/$name.prompt" | head -1); own=; for L in A B C; do echo "$off" | grep -q "$L" || own=$L; done; first=$(echo $off | awk "{print \$1}"); text="RANK: $own > $first
x"; if [ -n "$out" ]; then printf "%s\n" "$text" >"$out"; else printf "%s\n" "$text"; fi'

export PATH="$ok:$PATH"

# --- seats ---
got=$("$SC" seats)
if printf '%s\n' "$got" | grep -qx claude && printf '%s\n' "$got" | grep -qx codex && printf '%s\n' "$got" | grep -qx agent; then
  pass "seats lists claude codex agent"
else
  fail "seats: $got"
fi

# --- new ---
round=$("$SC" new "pick a color")
if [ -f "$round/brief.md" ] && grep -q "pick a color" "$round/brief.md"; then
  pass "new writes brief"
else
  fail "new did not write brief ($round)"
fi
if printf '%s' "$round" | grep -Eq '^\.sealed-council/[0-9]{8}-[0-9]{6}-[0-9a-f]{4}-'; then
  pass "new id has timestamp-hex-slug"
else
  fail "new id shape: $round"
fi

r2=$("$SC" new "pick a color")
if [ "$round" != "$r2" ]; then pass "two news same second get different ids"
else fail "colliding round ids: $round"; fi

# --- oversized brief ---
yes a | head -c 65537 > "$tmp/big.txt"
big=$("$SC" new "$tmp/big.txt")
if "$SC" ask "$big" claude codex agent >/dev/null 2>"$tmp/big.err"; then
  fail "oversized brief should be rejected"
else
  grep -q "64 KiB" "$tmp/big.err" && pass "oversized brief rejected" || fail "oversized: $(cat "$tmp/big.err")"
fi

# --- ask ---
rm -rf "$STUB_LOG"/*
mkdir -p "$STUB_LOG"
if "$SC" ask "$round" >/dev/null 2>"$tmp/ask.err"; then
  pass "ask exit 0 with 3 seats"
else
  fail "ask failed: $(cat "$tmp/ask.err")"
fi
id=$(basename "$round")
adir="$SC_HOME/rounds/$id/answers"
if [ -f "$adir/claude.md" ] && [ -f "$adir/codex.md" ] && [ -f "$adir/agent.md" ]; then
  pass "ask writes answers under SC_HOME"
else
  fail "missing SC_HOME answers"
fi
if grep -q "I am Claude" "$adir/claude.md"; then pass "self-id answer stored"
else fail "claude answer missing self-id"; fi
if ls "$round"/answer-*.md >/dev/null 2>&1 || ls "$round"/*.md 2>/dev/null | grep -qv brief.md; then
  fail "ask leaked answers into the round dir"
else
  pass "ask does not write answers into the project round"
fi

# F7 rerun: skip existing unless --replace
rm -rf "$STUB_LOG"/*
mkdir -p "$STUB_LOG"
if "$SC" ask "$round" >/dev/null 2>"$tmp/rerun.err"; then
  if [ -f "$STUB_LOG/claude.pwd" ]; then fail "rerun asked a seat that already answered"
  else pass "repeat ask skips existing answers"; fi
else
  fail "repeat ask failed: $(cat "$tmp/rerun.err")"
fi
rm -rf "$STUB_LOG"/*
mkdir -p "$STUB_LOG"
if "$SC" ask --replace "$round" >/dev/null 2>"$tmp/repl.err"; then
  if [ -f "$STUB_LOG/claude.pwd" ]; then pass "ask --replace reruns seats"
  else fail "--replace did not rerun"; fi
else
  fail "ask --replace failed: $(cat "$tmp/repl.err")"
fi

iso_ok=1
for s in claude codex agent; do
  p="$STUB_LOG/$s.pwd"
  [ -f "$p" ] || { iso_ok=0; break; }
  case $(cat "$p") in
    "$proj") iso_ok=0 ;;
  esac
done
if [ "$iso_ok" -eq 1 ]; then pass "default ask uses a temp dir, not the project"
else fail "default ask cwd was the project"; fi

round_repo=$("$SC" new "repo flag")
rm -rf "$STUB_LOG"/*
mkdir -p "$STUB_LOG"
if "$SC" ask --repo "$round_repo" >/dev/null 2>"$tmp/repo.err"; then
  if grep -qx "$proj" "$STUB_LOG/claude.pwd" && grep -qx "$proj" "$STUB_LOG/codex.pwd"; then
    pass "ask --repo runs in the project cwd"
  else
    fail "--repo pwd: claude=$(cat "$STUB_LOG/claude.pwd" 2>/dev/null) proj=$proj"
  fi
else
  fail "ask --repo failed: $(cat "$tmp/repo.err")"
fi

# --- timeout ---
round_t=$("$SC" new "timeout case")
if PATH="$slow:$ok:$PATH" SC_TIMEOUT=2 "$SC" ask "$round_t" >/dev/null 2>"$tmp/to.err"; then
  grep -q "seat claude: timeout" "$tmp/to.err" && pass "timeout message + exit 0" || fail "timeout msg: $(cat "$tmp/to.err")"
else
  fail "timeout ask should still exit 0 with 2 answers ($(cat "$tmp/to.err"))"
fi
if [ ! -f "$SC_HOME/rounds/$(basename "$round_t")/answers/claude.md" ]; then
  pass "timeout writes nothing for that seat"
else
  fail "timeout left a claude answer"
fi

# G1 stderr last line
round_boom=$("$SC" new "stderr line")
if PATH="$boom:$ok:$PATH" "$SC" ask "$round_boom" >/dev/null 2>"$tmp/boom.err"; then
  grep -q "failed (exit 3): boom-err" "$tmp/boom.err" && pass "failed seat prints last stderr line" || fail "stderr line: $(cat "$tmp/boom.err")"
else
  fail "boom ask should still exit 0 ($(cat "$tmp/boom.err"))"
fi
if [ -s "$SC_HOME/rounds/$(basename "$round_boom")/logs/claude.err" ]; then pass "stderr saved under SC_HOME logs"
else fail "missing claude.err log"; fi

# --- fail one ---
round_f=$("$SC" new "fail one")
if PATH="$failone:$ok:$PATH" "$SC" ask "$round_f" >/dev/null 2>"$tmp/fail.err"; then
  grep -q "seat claude: failed (exit 3)" "$tmp/fail.err" && pass "fail message + exit 0" || fail "fail msg: $(cat "$tmp/fail.err")"
else
  fail "one failed seat should still exit 0"
fi

# --- all fail ---
round_af=$("$SC" new "all fail")
if PATH="$failstub:$PATH" "$SC" ask "$round_af" claude codex agent >/dev/null 2>"$tmp/allfail.err"; then
  fail "all-fail should exit 1"
else
  pass "all-fail exit 1"
fi

# --- seal ---
if "$SC" seal "$round" >/dev/null 2>"$tmp/seal.err"; then
  pass "seal exit 0"
else
  fail "seal: $(cat "$tmp/seal.err")"
fi
nlet=0
for L in A B C; do [ -f "$round/$L.md" ] && nlet=$((nlet + 1)); done
if [ "$nlet" -eq 3 ]; then pass "seal wrote A.md B.md C.md"
else fail "letters=$nlet"; fi
map="$SC_HOME/maps/${id}.tsv"
if [ -f "$map" ]; then pass "map outside project"
else fail "missing map $map"; fi
case $map in
  "$proj"*) fail "map lives under the project" ;;
  *) pass "map path is not in the project" ;;
esac
rows=$(grep -c $'\t' "$map" || true)
if [ "$rows" -eq 3 ]; then pass "map has 3 rows"
else fail "map rows=$rows $(cat "$map")"; fi
if grep -q "I am Claude" "$round"/[A-Z].md; then pass "self-id answer still seals"
else fail "sealed files lost self-id text"; fi
if [ -f "$adir/claude.md" ] && [ -f "$adir/codex.md" ] && [ -f "$adir/agent.md" ]; then
  pass "original answers stay in SC_HOME"
else
  fail "seal moved/deleted original answers"
fi
if find "$round" -name '*claude*' -o -name '*codex*' -o -name '*agent*' | grep -q .; then
  fail "round dir has seat names after seal"
else
  pass "round dir has no seat names after seal"
fi
# filenames only: no answer-*.md
if ls "$round"/answer-*.md >/dev/null 2>&1; then fail "answer-* still in round"
else pass "no answer-* in round"; fi

if "$SC" ask "$round" >/dev/null 2>"$tmp/sealedask.err"; then
  fail "ask after seal should refuse"
else
  grep -q "already sealed" "$tmp/sealedask.err" && pass "ask refuses after seal" || fail "sealed ask: $(cat "$tmp/sealedask.err")"
fi

# refuse existing target
round_ex=$("$SC" new "existing target")
"$SC" ask "$round_ex" >/dev/null 2>&1 || true
touch "$round_ex/A.md"
if "$SC" seal "$round_ex" >/dev/null 2>"$tmp/ex.err"; then
  fail "seal should refuse existing A.md"
else
  grep -q "already exists" "$tmp/ex.err" && pass "seal refuses existing target" || fail "existing: $(cat "$tmp/ex.err")"
fi

# dangling symlink
round_ds=$("$SC" new "dangling")
"$SC" ask "$round_ds" >/dev/null 2>&1 || true
ln -s /no/such/file "$round_ds/A.md"
if "$SC" seal "$round_ds" >/dev/null 2>"$tmp/ds.err"; then
  fail "seal should refuse dangling symlink"
else
  grep -q "already exists" "$tmp/ds.err" && pass "seal refuses dangling symlink" || fail "symlink: $(cat "$tmp/ds.err")"
fi

# seal failure mid-way leaves nothing published
round_mv=$("$SC" new "partial seal")
"$SC" ask "$round_mv" >/dev/null 2>&1 || true
shim="$tmp/shim"
mkdir -p "$shim"
cat > "$shim/mv" <<'EOF'
#!/bin/bash
real=/bin/mv
last=${!#}
case $last in
  *B.md) exit 1 ;;
esac
exec "$real" "$@"
EOF
chmod +x "$shim/mv"
if PATH="$shim:$PATH" "$SC" seal "$round_mv" >/dev/null 2>"$tmp/mv.err"; then
  fail "partial seal should fail"
else
  if [ -e "$round_mv/A.md" ] || [ -e "$round_mv/B.md" ] || [ -e "$round_mv/C.md" ] || [ -f "$SC_HOME/maps/$(basename "$round_mv").tsv" ]; then
    fail "partial seal left published files"
  else
    pass "seal failure mid-way left nothing published"
  fi
fi

# oversized answer rejected before rank (A4)
round_oa=$("$SC" new "oversize answer")
"$SC" ask "$round_oa" >/dev/null 2>&1 || true
"$SC" seal "$round_oa" >/dev/null 2>&1 || true
yes x | head -c 65537 > "$round_oa/A.md"
if "$SC" rank "$round_oa" >/dev/null 2>"$tmp/oa.err"; then
  fail "oversized answer should be rejected before rank"
else
  grep -q "64 KiB" "$tmp/oa.err" && pass "oversized answer rejected before rank" || fail "oversize answer: $(cat "$tmp/oa.err")"
fi

# F1: pre-existing map survives a failed seal
round_map=$("$SC" new "map survives")
"$SC" ask "$round_map" >/dev/null 2>&1 || true
mkdir -p "$SC_HOME/maps"
printf 'KEEP\n' > "$SC_HOME/maps/$(basename "$round_map").tsv"
if "$SC" seal "$round_map" >/dev/null 2>"$tmp/mapkeep.err"; then
  fail "seal should refuse existing map"
else
  if grep -qx KEEP "$SC_HOME/maps/$(basename "$round_map").tsv" && grep -q "already exists" "$tmp/mapkeep.err"; then
    pass "pre-existing map survives a failed seal"
  else
    fail "map keep: err=$(cat "$tmp/mapkeep.err") map=$(cat "$SC_HOME/maps/$(basename "$round_map").tsv")"
  fi
fi

# F2: 1-answer seal refused
round_1=$("$SC" new "one answer")
"$SC" ask "$round_1" >/dev/null 2>&1 || true
rm -f "$SC_HOME/rounds/$(basename "$round_1")/answers/codex.md" "$SC_HOME/rounds/$(basename "$round_1")/answers/agent.md"
if "$SC" seal "$round_1" >/dev/null 2>"$tmp/one.err"; then
  fail "1-answer seal should refuse"
else
  grep -q "at least 2" "$tmp/one.err" && pass "1-answer seal refused" || fail "1-answer seal: $(cat "$tmp/one.err")"
fi

# F2: 2-answer rank skipped
round_2=$("$SC" new "two answers")
"$SC" ask "$round_2" claude codex >/dev/null 2>&1 || true
"$SC" seal "$round_2" >/dev/null 2>&1 || true
if "$SC" rank "$round_2" >"$tmp/skip.out" 2>"$tmp/skip.err"; then
  if grep -q "2 answers: ranking skipped, host compares A and B" "$tmp/skip.out" && ! ls "$round_2"/rank-*.md >/dev/null 2>&1; then
    pass "2-answer rank skipped"
  else
    fail "2-answer rank: out=$(cat "$tmp/skip.out") files=$(ls "$round_2"/rank-*.md 2>/dev/null)"
  fi
else
  fail "2-answer rank should exit 0: $(cat "$tmp/skip.err")"
fi

# F8: combined rank prompt > 64 KiB
round_pr=$("$SC" new "prompt cap")
"$SC" ask "$round_pr" >/dev/null 2>&1 || true
"$SC" seal "$round_pr" >/dev/null 2>&1 || true
yes x | head -c 40000 > "$round_pr/A.md"
yes y | head -c 40000 > "$round_pr/B.md"
if "$SC" rank "$round_pr" >/dev/null 2>"$tmp/pr.err"; then
  grep -q "prompt exceeds 64 KiB" "$tmp/pr.err" && pass "oversized rank prompt" || fail "combined prompt succeeded without 64 KiB msg: $(cat "$tmp/pr.err")"
else
  grep -q "prompt exceeds 64 KiB" "$tmp/pr.err" && pass "oversized rank prompt" || fail "combined prompt: $(cat "$tmp/pr.err")"
fi

# --- rank ---
rm -rf "$STUB_LOG"/*
mkdir -p "$STUB_LOG"
if "$SC" rank "$round" >/dev/null 2>"$tmp/rank.err"; then
  pass "rank exit 0"
else
  fail "rank: $(cat "$tmp/rank.err")"
fi
nr=0
for f in "$round"/rank-*.md; do [ -f "$f" ] && nr=$((nr + 1)); done
if [ "$nr" -eq 3 ]; then pass "rank wrote 3 nameless files"
else fail "rank files=$nr"; fi
if find "$round" -name 'rank-*' | grep -E 'claude|codex|agent' | grep -q .; then
  fail "rank filenames contain seat names"
else
  pass "rank files contain no seat names"
fi
# ranker never receives its own letter
own_ok=1
while IFS=$'\t' read -r letter seat hash; do
  p="$STUB_LOG/${seat}.prompt"
  if [ ! -f "$p" ]; then own_ok=0; continue; fi
  if grep -q "=== $letter ===" "$p"; then
    fail "ranker $seat received own letter $letter"
    own_ok=0
  fi
done <"$map"
if [ "$own_ok" -eq 1 ]; then pass "ranker never receives its own letter"; fi
if grep -q 'RANK: [A-Z] > [A-Z]' "$STUB_LOG/claude.prompt" && ! grep -q 'RANK: [A-Z] > [A-Z] > [A-Z]' "$STUB_LOG/claude.prompt"; then
  pass "rank prompt example matches two letters"
else
  fail "rank example: $(grep RANK "$STUB_LOG/claude.prompt" | head -1)"
fi

# D0: seat stdout during rank must not reach the terminal
round_leak=$("$SC" new "rank leak")
"$SC" ask "$round_leak" >/dev/null 2>&1 || true
"$SC" seal "$round_leak" >/dev/null 2>&1 || true
leakd="$tmp/leak"
write_stub "$leakd/codex" 'echo LEAK-RANK-STDOUT; off=$(sed -n "s/.*RANK: \([A-Z >]*\) (only.*/\1/p" "$STUB_LOG/$name.prompt" | head -1); text="RANK: $off
why"; if [ -n "$out" ]; then printf "%s\n" "$text" >"$out"; else printf "%s\n" "$text"; fi'
if PATH="$leakd:$ok:$PATH" "$SC" rank "$round_leak" >"$tmp/leak.out" 2>"$tmp/leak.err"; then
  if grep -q LEAK-RANK-STDOUT "$tmp/leak.out"; then fail "rank leaked seat stdout to the terminal"
  else pass "rank seat stdout does not reach the terminal"; fi
else
  if grep -q LEAK-RANK-STDOUT "$tmp/leak.out"; then fail "rank leaked seat stdout (and failed): $(cat "$tmp/leak.err")"
  else pass "rank seat stdout does not reach the terminal"; fi
fi

# G3 rerun refused
if "$SC" rank "$round" >/dev/null 2>"$tmp/rerank.err"; then
  fail "rank rerun should refuse"
else
  grep -q "round already ranked" "$tmp/rerank.err" && pass "rank rerun refused" || fail "rerank: $(cat "$tmp/rerank.err")"
fi

# F3 one-fail rank
round_rf=$("$SC" new "rank one fail")
"$SC" ask "$round_rf" >/dev/null 2>&1 || true
"$SC" seal "$round_rf" >/dev/null 2>&1 || true
if PATH="$failone:$ok:$PATH" "$SC" rank "$round_rf" >/dev/null 2>"$tmp/rf.err"; then
  grep -q "seat claude: failed (exit 3)" "$tmp/rf.err" && pass "one-fail rank exit 0" || fail "one-fail rank msg: $(cat "$tmp/rf.err")"
else
  fail "one-fail rank should exit 0 with 2 ranks ($(cat "$tmp/rf.err"))"
fi

# F3 all-fail rank
round_ra=$("$SC" new "rank all fail")
"$SC" ask "$round_ra" >/dev/null 2>&1 || true
"$SC" seal "$round_ra" >/dev/null 2>&1 || true
if PATH="$failstub:$PATH" "$SC" rank "$round_ra" >/dev/null 2>"$tmp/ra.err"; then
  fail "all-fail rank should exit 1"
else
  pass "all-fail rank exit 1"
fi

# F4 child sleeper killed with the group
spawn="$tmp/spawn"
write_stub "$spawn/claude" 'sleep 30 & echo $! > "$STUB_LOG/child.pid"; wait'
round_ch=$("$SC" new "child timeout")
rm -rf "$STUB_LOG"/*
mkdir -p "$STUB_LOG"
PATH="$spawn:$ok:$PATH" SC_TIMEOUT=2 "$SC" ask "$round_ch" >/dev/null 2>"$tmp/ch.err" || true
if [ -f "$STUB_LOG/child.pid" ]; then
  chpid=$(cat "$STUB_LOG/child.pid")
  sleep 1
  if kill -0 "$chpid" 2>/dev/null; then fail "timeout left child $chpid alive"
  else pass "timeout killed child process group"; fi
else
  fail "child stub did not record pid"
fi

# F5 relative SC_HOME
if SC_HOME=rel "$SC" seats >/dev/null 2>"$tmp/rel.err"; then
  fail "relative SC_HOME should be rejected"
else
  grep -q "absolute" "$tmp/rel.err" && pass "relative SC_HOME rejected" || fail "rel SC_HOME: $(cat "$tmp/rel.err")"
fi

# G3 unwritable ranks table leaves no counted rank
round_uw=$("$SC" new "unwritable ranks")
"$SC" ask "$round_uw" >/dev/null 2>&1 || true
"$SC" seal "$round_uw" >/dev/null 2>&1 || true
mkdir -p "$SC_HOME/maps/$(basename "$round_uw").ranks"
if "$SC" rank "$round_uw" >/dev/null 2>"$tmp/uw.err"; then
  fail "unwritable ranks should fail"
else
  if ls "$round_uw"/rank-*.md >/dev/null 2>&1; then fail "unwritable ranks left rank files"
  else pass "unwritable ranks table leaves no counted rank"; fi
fi

# G4 bad RANK lines
round_dup=$("$SC" new "dup rank")
"$SC" ask "$round_dup" >/dev/null 2>&1 || true
"$SC" seal "$round_dup" >/dev/null 2>&1 || true
if PATH="$dup:$ok:$PATH" "$SC" rank "$round_dup" >/dev/null 2>"$tmp/dup.err"; then
  grep -q "bad RANK line" "$tmp/dup.err" && pass "duplicate letter rejected" || fail "dup rank succeeded without bad RANK: $(cat "$tmp/dup.err")"
else
  grep -q "bad RANK line" "$tmp/dup.err" && pass "duplicate letter rejected" || fail "dup: $(cat "$tmp/dup.err")"
fi

round_unk=$("$SC" new "unk rank")
"$SC" ask "$round_unk" >/dev/null 2>&1 || true
"$SC" seal "$round_unk" >/dev/null 2>&1 || true
if PATH="$unk:$ok:$PATH" "$SC" rank "$round_unk" >/dev/null 2>"$tmp/unk.err"; then
  grep -q "bad RANK line" "$tmp/unk.err" && pass "unknown letter rejected" || fail "unk rank succeeded without bad RANK: $(cat "$tmp/unk.err")"
else
  grep -q "bad RANK line" "$tmp/unk.err" && pass "unknown letter rejected" || fail "unk: $(cat "$tmp/unk.err")"
fi

round_own=$("$SC" new "own rank")
"$SC" ask "$round_own" >/dev/null 2>&1 || true
"$SC" seal "$round_own" >/dev/null 2>&1 || true
if PATH="$ownbad:$ok:$PATH" "$SC" rank "$round_own" >/dev/null 2>"$tmp/own.err"; then
  grep -q "bad RANK line" "$tmp/own.err" && pass "own letter rejected" || fail "own rank succeeded without bad RANK: $(cat "$tmp/own.err")"
else
  grep -q "bad RANK line" "$tmp/own.err" && pass "own letter rejected" || fail "own: $(cat "$tmp/own.err")"
fi

# G6 install preflight
ihome="$tmp/ihome"
mkdir -p "$ihome/.claude/skills"
echo x > "$ihome/.claude/skills/sealed-council"
if HOME="$ihome" "$ROOT/install.sh" >/dev/null 2>"$tmp/inst.err"; then
  fail "install should refuse pre-existing dest"
else
  if [ -e "$ihome/.agents/skills/sealed-council" ] || [ -e "$ihome/.local/bin/sealed-council" ]; then
    fail "install created links after conflict"
  else
    grep -q "refuse" "$tmp/inst.err" && pass "install preflight creates nothing on conflict" || fail "install: $(cat "$tmp/inst.err")"
  fi
fi

# G1 flag present
if grep -q skip-git-repo-check "$SC"; then pass "codex uses --skip-git-repo-check"
else fail "missing --skip-git-repo-check"; fi

# --- reveal ---
if "$SC" reveal "$round" >/dev/null 2>"$tmp/nov.err"; then
  fail "reveal without verdict should refuse"
else
  grep -q "write verdict.md first" "$tmp/nov.err" && pass "reveal refuses missing verdict" || fail "missing verdict: $(cat "$tmp/nov.err")"
fi
: > "$round/verdict.md"
if "$SC" reveal "$round" >/dev/null 2>"$tmp/emptyv.err"; then
  fail "reveal with empty verdict should refuse"
else
  grep -q "write verdict.md first" "$tmp/emptyv.err" && pass "reveal refuses empty verdict" || fail "empty verdict: $(cat "$tmp/emptyv.err")"
fi
echo ok > "$round/verdict.md"
echo tamper >> "$round/A.md"
rev=$("$SC" reveal "$round")
if printf '%s\n' "$rev" | grep -q $'A\t.*\tchanged'; then pass "reveal detects changed A.md"
else fail "reveal changed: $rev"; fi
okn=$(printf '%s\n' "$rev" | grep -c $'\tok$' || true)
if [ "$okn" -eq 2 ]; then pass "reveal reports other letters ok"
else fail "ok count=$okn $rev"; fi
if grep -q tamper "$round/A.md"; then pass "reveal does not overwrite changed A.md"
else fail "reveal overwrote A.md"; fi
if [ -f "$round/rank-claude.md" ] && [ -f "$round/rank-codex.md" ] && [ -f "$round/rank-agent.md" ]; then
  pass "reveal renames rank files to seats"
else
  fail "reveal rank rename missing"
fi

# never touch real home cache
if [ -d "$HOME/.sealed-council" ] && [ "$SC_HOME" != "$HOME/.sealed-council" ]; then
  : # may already exist from the user; we must not have used it
fi
case $SC_HOME in
  "$tmp"*) pass "SC_HOME stayed in temp" ;;
  *) fail "SC_HOME escaped temp" ;;
esac

if [ "$failed" -ne 0 ]; then echo FAIL; exit 1; fi
echo PASS
exit 0
