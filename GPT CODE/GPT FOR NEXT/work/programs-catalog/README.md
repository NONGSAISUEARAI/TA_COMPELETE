# Programs directory — 2026-10-11

Local update requested for the page shown after the existing password-only login. Reference: https://www.lee-mac.com/programs.html and the user's screenshot. Uses the idea of category headings followed by program tables, not Lee Mac's source, command inventory, version data or branding. Keeps the existing login's navy/blue/purple starfield palette.

Seven categories follow the existing `Autolisp Collection` folders, in their current order. Each has Program, Version and Updated columns with an explicitly empty/pending row. No command names, version numbers, timestamps, compatibility or download claims were invented. No link to the standalone Selection Slots video is added yet: command entries and protected media integration remain separate future work.

The three source files replace the previous after-login homepage, with a recoverable backup first. The existing local encryption builder reuses the private password, updates the encrypted payload and CSP hashes, and tests round-trip decryption, wrong-password rejection and tamper rejection. Credentials are not printed or copied into this staging folder. Login behavior and its password do not change. No GitHub write or publication is performed.

`source/index.html` is a plaintext editing/preview file, not the public entry point. Use the portfolio's `publish/index.html` for the password-only entry. Only publish/ belongs in a public web deployment. Keep source/, private/ and backups/ private. The existing unrelated zip is not refreshed by this update.
