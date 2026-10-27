RANK: C > B

C gives the more practical growth path: exact similarity scoring within a user’s notes before adding approximate indexing, explicit attention to filtered-search recall, asynchronous embedding updates, and storage estimates. It also addresses indexing the ownership filter more concretely.

B prematurely recommends approximate indexing, which adds complexity and can hurt recall when searches are restricted to small user subsets.

Both overpromise latency from average account size alone. Neither establishes query volume, note lengths, account-size skew, hardware, or a representative benchmark. C’s fixed corpus-size migration threshold is also unjustified.

Not checked: measured performance. Main risk: averages hide large accounts and contention with normal app traffic.