I’d first separate **bad source content, retrieval failures, and generation failures**. Changing the model won’t fix an obsolete article.

**Find where it fails**

Sample real support queries, including known failures, common intents, and questions with no documented answer. Have support experts label the correct answer, supporting article/passages, and whether the current corpus can answer it. Check article versions, effective dates, duplicates, and conflicting guidance.

For each query, inspect retrieved chunks and the final answer:

- Is the correct, current information in the corpus?
- Did retrieval return enough evidence to answer?
- Did the model use that evidence correctly, without adding unsupported claims?

Also run generation with expert-selected evidence. If that fixes the answer, retrieval is implicated; if it doesn’t, investigate generation or ambiguous documentation. Failures can overlap.

**First eval**

Build a small, human-reviewed benchmark of roughly 100–200 representative queries, with a held-out portion. Include outdated/conflicting content, multi-article questions, and unanswerable requests.

Measure separately:

- **Retrieval:** recall of required evidence at k, plus whether stale/conflicting evidence appears.
- **Answers:** factual correctness, currency, completeness, citation support, and appropriate abstention.

Report results by failure category and intent, not just one accuracy score. Use human grading first; calibrate any automated judge against those labels.

**Fixes, in order**

1. **Repair content and ingestion:** remove or supersede stale articles, resolve contradictions, verify updates reach the index, and preserve useful version/product metadata.
2. **Improve retrieval:** test metadata filters, hybrid lexical/vector search, and retrieving more candidates followed by reranking. Tune chunk boundaries and context using measured evidence coverage; don’t blindly increase top-k.
3. **Constrain generation:** require evidence-backed answers and citations; clarify or escalate when evidence is missing or conflicting.
4. **Only then test model upgrades or fine-tuning**, if failures persist with correct evidence.

Skipped architecture rewrites. Main risk: optimizing a benchmark that doesn’t represent production traffic; validate improvements on fresh queries.