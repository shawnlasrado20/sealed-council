# Changelog

## 0.1.0 - 2026-10-27

- Ask installed `claude`, `codex`, and Cursor `agent` the same question in separate processes, locally, with no API key.
- Seal answers as A/B/C; the sha256 map lives under `$SC_HOME`; a seat never ranks its own letter.
- Host writes `verdict.md` before names are revealed; sha256 check flags a changed answer.
- Skip rank when there are two answers, or when they already agree.
- Bash + coreutils only; macOS and Linux; tests in `tests/test.sh`.
- `bench/`: 12-task benchmark (one agent vs the council, blind AI judges in both orders), with all answers, ranks and judge replies.
- Skill, Claude Code plugin, and CLI via `./install.sh` (plugin and `npx skills add` do not put the CLI on PATH).
