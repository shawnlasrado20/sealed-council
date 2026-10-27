# sealed-council

Claude Code, Codex and Cursor answer the same question alone, then rank each other's answers with the names hidden.

![demo](docs/demo.gif)

- Independent answers in separate processes.
- Answers shuffled to A/B/C.
- A seat never ranks its own answer.
- Names revealed only after the host writes the verdict; sha256 check flags a changed answer.
- Runs your installed `claude -p`, `codex exec` and Cursor `agent -p` on your own plans, no API key, no OpenRouter.

## Install

```bash
git clone https://github.com/shawnlasrado20/sealed-council.git
cd sealed-council
./install.sh
```

That puts the skill in `~/.claude/skills/sealed-council` and `~/.agents/skills/sealed-council`. `install.sh` links the CLI at `~/.local/bin/sealed-council`; add `~/.local/bin` to PATH if it is not there. It refuses to overwrite paths it did not create. `./install.sh --uninstall` removes only the symlinks that point into this clone.

Claude Code plugin: `/plugin marketplace add shawnlasrado20/sealed-council` then `/plugin install sealed-council@sealed-council`. Skill only; still run `./install.sh` for the CLI.

`npx skills add shawnlasrado20/sealed-council -g` is skill file only; still run `./install.sh` for the CLI.

Needs `claude`, `codex`, and/or `agent` (Cursor) on PATH. Bash + coreutils. macOS and Linux.

## Example: PR review

Live round on a refund endpoint. All three seats said BLOCK.

The top-ranked answer named a check-then-act refund: two concurrent requests both pass the 409 check and both call Stripe; a crash after Stripe succeeds leaves the order refundable again. Fix: atomically claim a durable refund row before calling Stripe, store a stable idempotency key, reconcile after.

The answer with the most code had an unsafe fix. Both reviewers who saw it found a flaw: it changes order state before the auth check, and rolling status back when Stripe errors reopens the order for a second refund (an order-id-only key also collides with variable amounts).

Reveal: A = Codex, B = Claude, C = Cursor.

## Compared with

| Repo | Difference |
|---|---|
| [karpathy/llm-council](https://github.com/karpathy/llm-council) | Web app, OpenRouter API key. |
| [hex/claude-council](https://github.com/hex/claude-council) | Real CLIs, names shown. |
| [aiwithremy/claude-skills-llm-council](https://github.com/aiwithremy/claude-skills-llm-council) | Claude subagents, five thinking lenses. |
| [epicsagas/council](https://github.com/epicsagas/council) | Anonymized, no Cursor seat. |

## How it works

1. You write a brief (the question).
2. `sealed-council new` makes a round; `ask` runs each seat alone (default: empty temp dir, brief only).
3. `seal` shuffles answers to `A.md` / `B.md` / …, names hidden. The map lives under `$SC_HOME`.
4. `rank` asks each seat to rank letters it did **not** write (skip this if they already agree).
5. The host writes `verdict.md` from A/B/C and the ranks **without** reading the map.
6. `reveal` prints who wrote what. `ask --repo` runs seats in your cwd so they can read code (they can then read anything readable).

## Cost

Up to 2 CLI runs per seat (each may make several model calls on your plan); worst case ~2× `SC_TIMEOUT` wall time (default 600 seconds). Plan limits assume normal individual use. Ranking can be skipped.

## Rounds so far

Two live rounds, kept in full (brief, sealed answers, ranks, verdict):

- [`examples/pr-review`](examples/pr-review): refund endpoint review. All three said BLOCK; ranks A > C > B; the answer with the most code ranked last.
- [`examples/one-run`](examples/one-run): how a zero-dep bash CLI should store a private file. Two seats agreed, one dissented.

## Benchmark

12 tasks (code review, system design, product, AI product), one agent alone vs the council, judged blind by a fresh Claude and a fresh Codex in both answer orders: **council 12, single 0** (46 of 48 votes). The council sees the single answer and costs about 7 agent calls instead of 1, and the judges are AI, not people. Tasks, every answer, the method and those caveats are in [`bench/`](bench/README.md).

## Limits

Identity-masked (names hidden), not a promise of anonymity. Seats run as you and can read any file you can read, not just `$SC_HOME`. Cursor ask mode is not a sandbox: it has been observed reading files outside its temp dir. `--repo` exposes the project (anything readable in cwd). Style can reveal authorship; an answer that names its author reveals it to other rankers. The host agent is trusted and could read the map; the skill says not to, until after the verdict. Cursor (`agent`) gets the prompt via argv, so it is visible in the process list. `$SC_HOME` must be an absolute path.

## Privacy

This script stores rounds locally and sends no telemetry. Each seat is your normal agent CLI, so briefs and answers go to that CLI's model provider. Round files in the project are `brief.md`, `A.md`/`B.md`/…, `rank-<n>.md`, `verdict.md`. Answers and the map live under `$SC_HOME` (default `~/.sealed-council`).

## License

MIT.
