# CHANGES

1. App updater and release-surface cleanup

This fork removes legacy update-management wiring and related release-surface references that were no longer part of the maintained product flow. The goal is to simplify runtime behavior and reduce maintenance risk by eliminating dead or obsolete update paths while keeping the app startup and core dictation behavior intact.

2. Setup and onboarding surface simplification

The setup/onboarding experience was trimmed to remove obsolete or noisy components and align the UI with the fork’s current scope. This includes streamlining informational sections and reducing coupling to external metadata so first-run flow stays clear and deterministic.

3. GitHub/community metadata handling updates

Community-facing metadata presentation was adjusted to match the fork’s reduced external dependency model. Where social/repository stats were previously fetched or displayed, the code now avoids fragile assumptions and uses safer defaults so the app remains stable even when remote API data is unavailable or intentionally de-scoped.

4. Persistence boundary tightening

Persistence entry points that were outside the intended long-term data model were removed or consolidated. The fork keeps persistence where it is product-critical (e.g., user settings and supported stores) and drops deprecated pathways, reducing accidental state drift and simplifying future migrations.

5. Internal state and integration consistency pass

Related state wiring, call sites, and view-model edges were normalized after the removals above so symbols, references, and behavior stay coherent. This pass focused on compile-time consistency and minimal behavioral change, ensuring remaining features still connect cleanly end-to-end.

6. Test and safety follow-through

Tests and supporting code were aligned with the forked behavior where applicable, and stale references were removed to keep the suite representative of current functionality. The emphasis was on preventing regressions from symbol removal and keeping maintenance cost low by avoiding unused paths.

## Needs a Mac

- Final Xcode 26 project build and archive validation.
- Code signing and notarization verification with release credentials.
- DMG creation + installer/open-path smoke test.
- On-device/manual validation of key workflows (recording, transcription, shortcuts, settings).
