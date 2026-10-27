## Finding where it fails

Take the roughly 20% of bad answers, plus a few hundred real queries, and label each failure by pipeline stage:

1. **Retrieval miss**: the right article exists but isn't in the top-3.
2. **Stale or conflicting source**: the article retrieved was outdated, or old and new versions both came back.
3. **Chunking damage**: the answer was split across chunk boundaries, or a table or steps list was cut off.
4. **Generation error**: the right context was there, but the model ignored it, mixed sources, or hallucinated.
5. **Coverage gap**: no article answers the question.

The resulting counts tell you where to spend effort. My guess is that retrieval and staleness will make up most of it.

## First eval to build

Build a **retrieval eval** before any answer-quality eval. Make 150 to 300 real user questions, each labeled with the correct article(s) and current answer. Measure recall@3 and recall@10, plus how often a deprecated article ranks above the current one. It's cheap and deterministic, and it separates retrieval failures from generation failures. Then add a small answer-level check, either an LLM judge validated against human labels or exact-fact checks, covering faithfulness to context and correctness.

## Fixes, in order

1. **Content hygiene.** Remove or flag outdated articles, add `last_updated` and product-version metadata, and filter or boost on it. Stale sources often explain "outdated" answers more than any model change would.
2. **Retrieval quality.**
   - Add hybrid search (BM25 plus vectors) to catch exact terms like error codes and feature names.
   - Add a cross-encoder reranker over the top 20 to 50 results.
   - Retrieve more than 3 results.
3. **Chunking.** Use smaller chunks that respect structure (around 300 to 500 tokens, split on headings), with the article title and section prepended. Return parent-article context when you can.
4. **Query handling.** Rewrite multi-turn and vague queries into standalone search queries.
5. **Generation.** Require answers grounded only in the context, with citations, and an "I don't know, escalate" path when retrieval confidence is low.
6. **Coverage.** Log unanswerable queries and send them to the content team.

Rerun the eval after each change and keep only the changes that improve it.
