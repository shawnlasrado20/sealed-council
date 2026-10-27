**Pick (1): `chmod 600` under `~/.toolname`.**

A zero-dependency bash tool only has the filesystem. `mkdir -p` and `chmod 600` (and `umask 077` before write) are already there on every Unix the script will run on. No extra packages, no platform split, no crypto to get wrong.

(2) is not zero-dep and not portable: Keychain is macOS-only; libsecret is a Linux stack. A small OSS bash CLI cannot take that as its store.

(3) looks stronger and is the only option that even tries the “same user, other process” goal. It still needs `openssl`/`gpg`, a passphrase prompt, and a place to keep that passphrase. Cache it and you are back to a readable file. Don’t cache it and unattended use dies. Easy to implement badly.

Honest limit: **0600 does not hide the file from other processes of the same UID.** Neither does Keychain (same-user clients can usually query it) or ciphertext (same-user can scrape tty, memory, or `ptrace`). Unix DAC cannot solve that threat. For a small OSS CLI, 0600 in a dedicated dot-dir is the honest, portable default — same pattern as `~/.ssh`. If the threat is really a hostile same-UID process, the tool is already on the wrong side of the trust boundary.
