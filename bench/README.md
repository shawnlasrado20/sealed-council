# Benchmark: one agent vs sealed-council

12 tasks: 4 code reviews, 4 system-design questions, 2 product questions, 2 AI-product questions. Each brief asks for at most 300 words. Prompts are in [`tasks/`](tasks), and every answer, rank and judge reply is in [`results/`](results) and [`judged/`](judged).

## Setup

- **Single:** Claude Code's own answer from the round (`results/<task>/single.md`).
- **Council:** Claude Code, Codex and Cursor answer sealed as A/B/C, rank each other blind, then a host (headless Claude, no tools) writes one final answer from the three answers and the ranks (`results/<task>/council.md`).
- **Judges:** a fresh headless Claude and a fresh Codex. They see the question plus "Answer 1" and "Answer 2", and are not told a council exists. Each judge sees every pair twice, once in each order, to cancel position bias. That makes 48 votes.
- A task goes to whichever side has more of its 4 votes; an even split is a tie.

Run it yourself: `bench/run.sh`, then `bench/judge.sh`, then `bench/score.py`. `bench/make_grade_page.py` builds a blind X/Y page if you want human grades instead.

## Results (27 Oct 2026, one run)

| Task | Claude judge (both orders) | Codex judge (both orders) | Result |
| --- | --- | --- | --- |
| 01-cache | council / council | council / council | council |
| 02-paginate | council / council | council / council | council |
| 03-sql | council / council | council / council | council |
| 04-bash | council / council | council / council | council |
| 05-webhooks | council / council | council / council | council |
| 06-multitenant | council / council | council / council | council |
| 07-search | single / council | council / council | council |
| 08-uploads | council / council | council / council | council |
| 09-pricing | single / council | council / council | council |
| 10-churn | council / council | council / council | council |
| 11-rag-wrong | council / council | council / council | council |
| 12-agent-cost | council / council | council / council | council |

**Council 12, single 0, tie 0.** 46 of 48 votes went to the council. The two single votes came from the Claude judge, which said the council answer ran further past the 300-word limit.

A full round (3 answers, 3 ranks, host) took 66 to 171 s per task, about 97 s on average, with three tasks running at once. The single answer is one of those three calls, so the council costs about 7 agent calls where one agent costs 1.

## Read this before quoting the number

- **The council saw the single answer.** Claude's answer is one of its three inputs, so this measures "three answers, blind ranks and a merge" against "Claude alone", not three agents against one at the same cost.
- **The judges are AI, and both also sit on the council.** No human graded these. Codex's text can end up in the merged answer it then judges.
- **Both sides ignore the word limit.** Most answers run 320 to 440 words. The council answer is usually a little longer.
- **12 tasks, one run.** No repeats, no variance estimate.
- **No failures:** all 36 seat answers and 36 ranks came back valid.
