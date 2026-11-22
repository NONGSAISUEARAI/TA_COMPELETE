# Programs verification — 2026-10-11 (Asia/Bangkok)

- Local source page returned HTTP 200. JavaScript syntax check passed.
- Seven named categories and seven semantic tables match the existing collection directories. Each table has Program, Version and Updated headers and an explicitly pending placeholder; no invented program data.
- TH/EN updates descriptions, table copy and controls. The background pause control updates its pressed state. Reduced-motion and hidden-page handling remain in the source.
- Desktop 1280 × 900 and mobile 390 × 844 checked, including the exact decrypted document inside a sandboxed srcdoc with the real parent's CSP. No horizontal document overflow. Mobile category links scroll within their own navigation area.
- Category links scroll the document inside the sandbox rather than navigating the parent. The bottom category now remains the current link at the end of the page.
- Browser logs returned no warning/error entries after the sandbox functional checks.
- Existing builder's encryption round-trip, wrong-password and tamper checks passed. Independent package check confirmed the decrypted title and category content, source digest and exact parent script/style CSP hashes. Private credential file's SHA-256 remained unchanged; credentials were not printed or copied into staging.
- No real password was entered during browser QA. A QA-only wrapper rendered the exact decrypted payload to verify the frame, CSP and UI. Production login code is unchanged. An end-to-end human password-entry session was not independently repeated this turn.
- Previous homepage, encrypted payload, login stylesheet, ignore file and build-check metadata were backed up under backups/Before_Programs_20261011. No private access key was copied. backups/ was added to .gitignore to protect plaintext recovery copies.
- No original CAD code, recording or existing Selection Slots detail page was changed. No GitHub writes, publishing or zip update.

Limits: no cross-browser matrix, public deployment, independent security audit or integration of command entries/video links. Tables intentionally remain empty. Screenshots are local preview evidence, not proof of CAD functionality.
