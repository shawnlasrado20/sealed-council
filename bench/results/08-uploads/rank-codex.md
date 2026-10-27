RANK: C > A

C is more complete operationally: it limits decoded pixels, detects stuck processing, checks uploaded metadata, and allows processing retries without another upload. Its concrete status model and small deployment fit a two-person team.

A also addresses the core memory problem and adds useful privacy handling, cleanup, and alerting. However, it offers too many infrastructure alternatives and misses an explicit decoded-pixel limit—a compressed file’s byte size does not bound memory use.

Both exceed the 300-word limit and overstate size enforcement through signed upload rules; the chosen upload mechanism must actually support those constraints. Both should explicitly require ownership checks and private originals.

Not checked: implementation behavior. Main risk: insufficient upload validation or decoded-image limits can still cause abuse or memory exhaustion.