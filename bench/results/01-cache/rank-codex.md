RANK: B > A

B provides the stronger fix: it bounds cache growth and cleans up per-key locks. A identifies unbounded growth but leaves both cached entries and locks unbounded. A also incorrectly claims concurrent dictionary operations can corrupt the dictionary in free-threaded builds.

B correctly flags potential cross-source contamination, though its implementation leaves that issue unresolved. Its shorter negative TTL changes behavior without a stated requirement; caching `None` is already correct. B also exceeds the 300-word limit substantially and assumes a GIL-enabled runtime.

Both overstate backward clock jumps as causing entries to “never” expire; ordinary finite adjustments delay expiration.

Not checked: runtime execution. Remaining risk: both fixes can reuse data across different `fetch` sources.