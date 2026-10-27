Pick **(3): encrypt with a user passphrase**, requested interactively and never stored.

`chmod 600` protects against *other users*. Processes running as the same user can ordinarily read the file.

Keychain/libsecret provide useful credential storage, but access depends on platform policy and session state. They do not inherently guarantee isolation from other processes running as the same user, and libsecret adds a dependency.

Passphrase encryption can protect the stored file while locked, provided the passphrase is strong and encryption uses a vetted implementation with authenticated encryption and a suitable password derivation function.

**The constraint conflict:** Bash has no built-in cryptography. If “zero dependency” literally excludes an external cryptographic implementation, none of these options fully meets the requirement. Relax that constraint; don’t implement cryptography in shell.

Skipped: implementation details. Risk: same-user malware may capture the passphrase or plaintext while the tool is running.