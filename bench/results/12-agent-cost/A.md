# Fixing the unit economics of a 20 USD/month coding agent

**The numbers:** 30 tasks x 1.10 USD = 33 USD of cost per user against 20 USD of revenue, a loss of 13 USD per user. Just breaking even means cutting cost per task by about 40%. A healthy gross margin (60% or more) needs a cut of roughly 75%, to about 0.25 to 0.30 USD per task, or a pricing change.

**In priority order:**

1. **Prompt caching.** Agent loops resend the same system prompt, tool definitions and repo context on every step. Cached input tokens cost a small fraction of normal ones. This is usually the biggest single saving (often 40 to 60%), and users notice nothing.

2. **Context discipline.** Trim tool outputs: cap file reads, truncate logs, summarize long command results. Fetch only the relevant code instead of dumping whole files. Compact the conversation history mid-task. Long contexts cost money on every turn, and pruning them often makes the agent more accurate too.

3. **Model routing.** Use a cheap, fast model for file search, reading, summarizing, simple edits and lint fixes. Save the frontier model for planning, hard debugging and final review. Most steps in a typical task are routine.

4. **Cut waste from retries.** Measure cost per *successful* task. Find the loops: repeated failed edits, flaky tool calls, the agent re-reading the same files. Add stop conditions, better tool error messages, and validation earlier in the task. Fewer retries means lower cost and a better product.

5. **Fix pricing last, but fix it.** Usage is almost certainly skewed, with a small share of heavy users causing most of the loss. Include a task or credit allowance in the 20 USD plan, add a Pro tier for heavy users, and charge for overage. The median user's experience stays the same.

**Don't:** quietly downgrade the default model, or cap tasks without telling users. Both cut costs by making the product worse.

**Key metric:** gross margin per active user, tracked by cohort and by task type.
