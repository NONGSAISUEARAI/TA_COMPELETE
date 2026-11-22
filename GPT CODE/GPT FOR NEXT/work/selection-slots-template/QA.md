# UI verification — 2026-10-11

Checked in the Codex in-app browser over localhost; page returned HTTP 200. No original CAD code was modified or executed, and no GitHub publication performed.

- Save / Load / Add / Remove tabs display their actual command names and helper information.
- Keyboard Home selects Save; TH/EN changes command descriptions and interface copy.
- Invalid non-GIF file rejected. A generated one-pixel GIF fixture loaded correctly using the local chooser. This fixture is test-only, outside the template, and is not a CAD demonstration.
- Image expansion opened a dialog; Escape closed it. A selected GIF stayed associated with Save when switching to Load and back. Clear returned the frame to its placeholder.
- Local GIF uses a Blob URL. No upload endpoint, network API or browser storage code is present. Clipboard copy has a manual fallback; clipboard success was not independently verified.
- Background pause works. Canvas defaults to static for prefers-reduced-motion and pauses in hidden tabs. GIF animation itself is not paused by the star control.
- Responsive checks at 1280 × 900 and 390 × 844 showed no horizontal document overflow. Mobile placeholder height adjusted so the filename stays inside the frame above its caption. Temporary viewport override reset.
- Browser console inspection returned no warning/error entries after the functional tests. JavaScript syntax check passed.
- Preview screenshots contain placeholders only, not fabricated CAD results or real user-selected media.

Not verified: a cross-browser matrix, deployed HTTPS hosting, real CAD GIF recordings, oversized GIF test, independent security audit, or integration with the encrypted portfolio. Template remains outside publish/; adding it to the public site requires a separate integration step.
