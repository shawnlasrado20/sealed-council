---
name: sealed-council
description: >
  Run a local identity-masked council: each installed coding-agent CLI answers
  alone, names hidden, then ranks the others. Use for hard decisions, design
  choices, when the user says "council this", or "get a second opinion from my
  other agents".
---

# sealed-council

Your agents mark the papers, not the names. Identity-masked (names hidden).

You are the **host**. Drive the CLI; do not pretend to be a seat.

## Before you start

1. Count installed seats (`sealed-council seats`). Tell the user the call count **before** asking: up to **2 CLI runs per seat** (each run may make several model calls on their plan). Worst case ~2× `SC_TIMEOUT` wall time (default 600s).
2. Do not send secrets or employer-confidential code to seats the user has not approved.
3. Default `ask` runs each seat in a fresh empty temp dir with only the brief. `ask --repo` runs in the project cwd: seats can then read anything readable. Say that before using `--repo`.
4. Seats run as the same OS user and can read `$SC_HOME` (named answers and the map). An answer that names its author reveals it to other rankers.

## Procedure

1. Write a short brief (the question and any context the seats are allowed to see).
2. `sealed-council new <brief-file-or-text>` — note the round dir it prints.
3. `sealed-council ask <round>` (add `--repo` only if the user approved reading the project).
4. `sealed-council seal <round>` — round dir then holds `brief.md` plus `A.md` / `B.md` / …
5. Read A/B/C. If they **agree on the decision**, skip rank and say so. Peer rank needs 3 answers (each ranker sees the other two). With 2, the CLI prints `2 answers: ranking skipped, host compares A and B` and exits 0 — compare A and B yourself.
6. Otherwise `sealed-council rank <round>`. Rank files are `rank-<n>.md` (no seat names). Each seat is given only letters it did not write. Need at least 2 valid `RANK:` files.
7. Write `<round>/verdict.md` from A/B/C and the ranks. **Do not** read `~/.sealed-council/maps` or `$SC_HOME/maps` before the verdict.
8. `sealed-council reveal <round>`. Show the user the verdict, then who wrote what.

## Rules

- Never invent a missing seat or a missing letter.
- Never read the map before `verdict.md` exists.
- Never call this "blind". Names are hidden; style can still reveal authorship. You are trusted and could read the map — don't, until after the verdict.
- Answers live under `$SC_HOME` (default `~/.sealed-council`), not as `answer-<seat>.md` in the project.
