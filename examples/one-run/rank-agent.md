RANK: A > B

A is the better answer because it honors the hard constraint: a portable bash tool with no extra libraries. Mode `600`/`700` is the only option that exists on every POSIX box. A also states the security model correctly: the kernel’s boundary is the user ID. Same-UID processes can read a file, query an unlocked keyring, or scrape memory, so (2) and (3) do not buy real isolation for an unsigned script. Passphrase encryption only helps while the secret is locked, then fails the moment the user types it—or it gets cached—and it needs an external crypto binary.

B is right that `chmod` does not stop same-user reads, and it names the constraint clash cleanly. It still picks (3), which the brief forbids if “zero dependency” is literal, and it oversells at-rest encryption as the fix. A’s pick is implementable; B’s is not, unless you drop the constraint.
