# CHANGES — Speakey fork of Megaphone

Fork base: [Kuberwastaken/megaphone](https://github.com/Kuberwastaken/megaphone) (MIT). This fork hardens it for personal/product use under the Devvor org. Each numbered change is one or more commits.

## 1. Auto-updater removed entirely (safety)

- Deleted `Sources/UpdateManager.swift` and every reference: settings Updates card, menu-bar "Check for Updates" item, post-transcription update reminder overlay, all `update*` UserDefaults keys.
- The app now has **zero update mechanism and zero external release surface**. Updates happen by rebuilding from source — no third-party server can push code to this app.
- The old updater verified publisher identity, but a compromised upstream (GitHub account or his `updates.json` host) would still pass that check because the attacker would hold the signing identity. Removing the mechanism removes the class of risk.

## 2. All network calls removed from app code (privacy + safety)

- Removed the GitHub stats feature (stargazers/contributors fetch + UI) from both SetupView and SettingsView, and deleted `GitHubMetadataCache`.
- Verified end state: **zero** `URLSession`/`URLRequest`/`NWConnection` usages in `Sources/` and `Launcher/`. The only network-adjacent code left is `NetworkMonitor.swift` (local connectivity status via `NWPathMonitor`, no data transfer) and Apple's system-managed SpeechAnalyzer model download (a system API, not app code).
- Remaining URLs in code are static links the user can click (open in browser), never fetched by the app.

## 3. Rebrand: Megaphone → Speakey

- App name, menu items, notifications, setup flow, and UserDefaults domain now Speakey; bundle id `com.devvor.speakey` (dev build: `com.devvor.speakey.dev`).
- MIT license kept; attribution added in README + `NOTICE`: "Speakey is based on Megaphone by Kuberwastaken."

## 4. Recording retention off by default (privacy)

- Raw dictation audio and run history are **no longer persisted to disk** unless the user enables "Save recordings & history" in Settings (default OFF; `persistHistoryEnabled`).
- With it off, history is in-memory only; audio files are never written to Application Support.

## 5. Vocabulary hints (accuracy)

- The existing learnable DictionaryStore feature is kept.
- Added bundled `Resources/vocabulary.txt` (40 crypto/DeFi + developer terms: perp, OI, funding, Hyperliquid, liquidation cascade, CoreML, Parakeet, etc.). Seeded into the dictionary on first launch when the store is empty.
- Added a user-editable merge path: `~/Library/Application Support/Speakey/vocabulary.txt` is merged at startup if present, so hints can be maintained in plain text.
- Makefile copies `vocabulary.txt` into the app bundle's Resources.

## 6. Transcript logging audit (privacy)

- Swept all `print`/log statements: no transcript text is logged anywhere; existing code already logged only counts/confidence/status. (Verified by grep — none found.)

## 7. What was NOT changed

- The core engine (Apple SpeechAnalyzer streaming + FoundationModels cleanup), the fn-key handling, overlay, and smart-cleanup pipeline are untouched — this fork keeps the parts that make dictation accurate, and removes the parts that phone home, auto-update, or persist your voice.

## Needs a Mac

- Final Xcode 26 build (`make`), code signing, and DMG creation.
- On-device smoke test: fn-hold dictation, hands-free mode, vocabulary hints effect, Settings toggle for retention.
