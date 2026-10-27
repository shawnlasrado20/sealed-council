RANK: A > C

A names the high-impact failures with outcomes: empty or failed directory change deleting in the wrong place, splitting, listing parse errors, option-like names, recursive delete, and ignored errors. The rewrite actually blocks those: absolute directory, no directory change, regular files only, a minimum backup count, a run lock, and a deletion record. That is the right bar for nightly irreversible cleanup.

C is denser and nearer the length cap, and adds hidden names, clocks, links, and environment. Its rewrite is careful with option parsing, links, and refusing the root directory. It still can delete every backup if new ones stop, and concurrent runs are only warned about. Safer policy belongs in the script. A’s extra length is the main flaw.
