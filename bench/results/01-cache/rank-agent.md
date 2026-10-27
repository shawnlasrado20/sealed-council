RANK: B > C

B is the better answer because it lists the bugs that matter under the given load and ships a fix that still lets other requests proceed. Stampede, wall-clock TTL, unbounded growth, and a fetch-blind key are all real; per-key locking, a second lookup after the wait, monotonic expiry, an LRU cap, and a shorter miss TTL match a many-thread server with a 2s fetch.

C is sharper on two points B fumbles: `(None, t)` is already a valid hit, so “None sharing TTL” is a design choice, not a defect; and overlapping fetches can commit a stale write. C also correctly treats the fetch key as contract-dependent.

C’s patch still loses. One lock around `fetch` serializes every uid for two seconds, so hits stall on an unrelated miss. That fails the brief. FIFO eviction and full-TTL None are weaker too. Better diagnosis on two nits does not outweigh a lock that blocks the whole cache.
