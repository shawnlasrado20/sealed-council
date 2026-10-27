RANK: C > B

C's safe version is the stronger one. It enforces what B only recommends: it requires exactly one absolute directory argument, uses `cd -P --`, refuses `/`, sets nullglob, skips symlinks and non-regular files, and uses plain `rm --` with no `-r`. It also covers risks B misses: overlapping cron runs, clock skew and future timestamps, the cron PATH/environment, and the race between checking a file and deleting it.

B is tidier, and its `find -maxdepth 1 -type f -mtime +30 -delete` one-liner is idiomatic. It also makes the best practical point of either answer: keep the newest N copies so a stalled backup job doesn't lead to every archive being deleted. But B gets `-mtime +30` wrong: it calls it "strictly older than 30×24h", when it actually means 31 or more whole days. It accepts relative paths despite advising against them, and `find --` isn't portable.

Both answers likely go over the 300-word limit, C by a bit more. Its inclusion of hidden files also quietly changes what the script does.
