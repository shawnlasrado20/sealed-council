**The gap:** 30 tasks × $1.10 = $33 of LLM cost against $20 of revenue. That is a $13 loss per user before infrastructure, support and payment fees. Breaking even needs a cost cut of about 40%. A healthy gross margin (60%+) needs roughly 75%, to about $0.25–0.30 per task, or a pricing change.

**In priority order:**

1. **Measure cost per *successful* task.** Break it down by task type, usage level, retries and abandoned runs. A cheap attempt that fails is an expensive outcome. Every change below should be checked against completion rate, not only token savings.

2. **Cache and trim context.** Agent loops resend the same system prompt, tool definitions and repo context on every step. Cache them. Retrieve only the relevant files instead of whole files or the whole repo. Truncate logs and long tool output, and compact old turns. This is likely the biggest saving and users won't see it, but keep any context the task needs to be correct.

3. **Stop wasted loops.** Detect when the agent is making no progress or repeating failed edits. Give tools clearer error messages, validate earlier, and fail fast with a clear message. This lowers cost and makes the agent better.

4. **Route models by difficulty.** Use a cheap model for search, reading, summarizing and simple edits. Use the frontier model for planning, hard debugging and recovery, and switch up to it automatically when checks fail.

5. **Match pricing to usage.** Keep a useful $20 plan. Check whether a small group of heavy users drives most of the loss. If so, add transparent overage or a higher tier. Use credits rather than a flat task count, because a typo fix and a migration cost very different amounts. Show cost estimates before expensive runs and let users set spending limits.

6. **Negotiate volume discounts** once you understand usage. Discounts help, but they won't fix a plan that is priced too low.

**Avoid:** quietly downgrading the default model, or arbitrary hidden caps.

**Reality check:** if efficient tasks still cost about $1, $20 can't include 30 of them. Test any price change against retention and contribution margin.
