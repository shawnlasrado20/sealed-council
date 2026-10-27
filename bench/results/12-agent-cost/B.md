**Cut cost per task first, then price to remaining usage, then stop paying for failed work.** Today you take in $20 and spend ~$33 (30 × $1.10). You need COGS well under $20 without shrinking what a good task can do.

**1. Stop paying full context on every step.** Long context + many tool calls is the bill. Cache the system prompt and repo snapshot. Don’t resend unchanged files. Compact tool results. Summarize old turns instead of replaying the transcript. This is the largest cut and usually makes the agent faster, not worse.

**2. Route models.** Use a cheap model for search, grep, formatting, and “what next.” Use the frontier model only for hard edits and judgments. A $1.10 blended cost means the expensive model is on too often.

**3. Charge for tokens, not a fake “unlimited” seat.** Keep $20 as a generous included budget *after* (1) and (2). Sell overage credits or a power-user tier. The fat tail, not the median user, breaks the P&L. Average users shouldn’t feel a worse product; 200-task users should pay.

**4. Don’t pay for retries and runaway loops.** Cap silent retries, detect no-progress loops, and fail fast with a clear error. Every retry is a full-price task that didn’t ship. Fewer loops is cheaper *and* a better agent.

**5. Raise list price only after the cost curve is honest.** If a solid task still costs ~$0.40–0.60, $20 can work with ~30 included tasks and overage. If it stays near $1, $20 unlimited cannot. Don’t hide that with hard daily caps that make the product feel broken.

Do not: switch everything to a weak model, hard-cap at 18 tasks, or tax the typical user to subsidize loops. Fix the token path, then align price with who actually consumes it.
