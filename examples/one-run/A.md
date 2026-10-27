**Pick (1): a file under `~/.toolname` with `chmod 600`, and the directory set to `chmod 700`.**

**Why:**

- **No dependencies.** It only needs `umask`, `mkdir` and `chmod`, which every POSIX system has. The Keychain needs `security`, which only exists on macOS. libsecret needs `secret-tool` and a running D-Bus session, which headless servers, containers and SSH sessions often lack. Supporting both doubles the code paths and still leaves gaps.
- **The threat model doesn't favour the other options.** The real UNIX security boundary is the user ID. File mode bits stop other users. Nothing simple stops another process running as the *same* user: it can read the file, call `secret-tool lookup`, or read your memory. On Linux, libsecret gives no per-app isolation once the keyring is unlocked. Only the macOS Keychain's per-app ACLs add some protection, and only for signed binaries, not a bash script.
- **A passphrase adds friction without real protection.** The user has to type it every run, or it gets cached somewhere, which brings back the same problem. It also needs `openssl` or `gpg`, which are dependencies with flags that differ between versions.

**Implementation notes:**
- Use `umask 077` before creating the file so there's no window where it's world-readable.
- Respect `$XDG_CONFIG_HOME` if it's set.
- Refuse to run if the permissions are looser than expected, as `ssh` does.
- Document honestly that this protects against other users, not against malware running as the same user.

Optionally, use the Keychain or libsecret when they're detected, and fall back to the file.
