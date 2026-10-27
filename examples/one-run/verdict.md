# Verdict

**Ranks:** C > B, A > B, C > A. C first twice, A once, B never first.

**Decision: (1) `chmod 600` in a `700` dot-dir, with `umask 077` before writing.** A and C agree; B is the dissent.

- Only option that is truly zero-dependency and portable (A, C).
- Say the limit plainly: it stops other users, not other processes of the same user. No option here fully does (all three agree).
- B's point stands as a footnote: passphrase encryption protects data at rest, but needs an external crypto tool and a passphrase you either retype or store.
- Take from A: respect `$XDG_CONFIG_HOME`, refuse to run on loose permissions like `ssh`.
