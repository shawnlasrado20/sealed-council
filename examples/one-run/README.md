# Example round

Question: how should a zero-dep bash CLI store a private file? Options: chmod 600, Keychain/libsecret, or a passphrase.

Live run: `ask` 22 s, `rank` 28 s, all three seats.

Reveal: A = claude, B = codex, C = agent (Cursor). C ranked first twice.

Host verdict: pick (1) chmod 600 in a 700 dir, umask 077. A and C agree; B dissented.
