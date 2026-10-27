**Find where it fails.** Sample 100–200 real tickets (or failed spot-checks). For each, log query, retrieved chunks, top-3 scores, answer, and a gold source if it exists. Label four failure types: *retrieval miss* (right article never in top-3), *chunk miss* (article found but the needed span is cut or stale), *generation error* (evidence was enough, model still wrong), *policy/outdated* (docs themselves are wrong). Also tag query type (how-to, billing, edge case, multi-hop). That split tells you whether the 20% is search, chunking, the model, or the corpus.

**First eval.** Build a small **grounded answerability set**, not a generic QA leaderboard. ~80–150 queries with: (a) a known-good article/span or “unanswerable,” (b) expected facts, (c) recency. Score three things: **Recall@3** (did the right chunk appear), **citation faithfulness** (every claim supported by retrieved text), **answer correctness** vs gold. Add an **abstain** check: if nothing relevant is retrieved, the bot should refuse. Run this before and after every change. Keep a live slice of recent tickets so you catch drift.

**Fixes, in order.**

1. **Corpus hygiene.** Dedup, drop or date-stamp superseded articles, fix titles/metadata. Outdated answers often start here.
2. **Retrieval.** Hybrid search (BM25 + vectors), query rewrite, and metadata filters (product, version, date). Raise *k* only if you rerank.
3. **Chunking.** Split on headings; keep 200–400 token chunks with title/parent context. 1,000-token chunks bury the fact.
4. **Rerank + cite.** Cross-encoder rerank top-20 → top-3–5. Force citations; refuse when scores are low or sources conflict.
5. **Generation last.** Tighter system prompt (“answer only from quotes”), then a smaller grounded model or tool-calling. Do not swap the LLM first—it will still hallucinate from bad context.

Ship the eval, then change one layer at a time. If Recall@3 is high and faithfulness is low, fix generation. If Recall@3 is low, ignore the model until search and chunks work.
