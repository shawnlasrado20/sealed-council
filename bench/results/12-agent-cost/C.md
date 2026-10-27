At $20/month, 30 tasks × $1.10 = **$33 in LLM costs**: a $13 loss before infrastructure, support, or payment fees. Keeping the same revenue requires cutting LLM cost by more than 39% just to break even.

I’d change these in order:

1. **Measure cost per successfully completed task.** Segment by task type and usage level. Track retries, abandoned runs, and user corrections alongside cost. Cheap attempts that fail are expensive outcomes.

2. **Remove wasted work.** Cache reusable context, retrieve relevant files instead of repeatedly sending the repository, trim redundant tool output, and stop loops that make no progress. Preserve context needed for correctness. These changes can improve both speed and cost.

3. **Route models by difficulty.** Use cheaper models for search, classification, and straightforward edits; reserve stronger models for planning, difficult debugging, and recovery. Escalate when checks fail. Validate routing against completion quality and rework, not token savings alone.

4. **Align pricing with expensive usage.** Keep a useful $20 entry plan, then offer transparent additional usage or higher tiers for heavy users. Avoid flat per-task allowances: a typo fix and a repository migration have different costs. Show an estimate before expensive runs and let users set spending limits. Preserve agent capability across tiers.

5. **Negotiate inference costs once usage is understood.** Pursue volume discounts and suitable providers, with quality and reliability checks. Discounts help; they cannot rescue structurally underpriced usage.

**Reality check:** if efficient execution still costs $1.10 per task, $20 cannot sustainably include 30 tasks. Someone must pay more, or the included usage must change. “Without making the product worse” should mean preserving successful outcomes—not unlimited subsidized consumption.

Skipped: arbitrary task caps and blanket model downgrades. Risk: pricing changes can reduce retention; test them against contribution margin and retained users.