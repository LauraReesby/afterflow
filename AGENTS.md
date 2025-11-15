# Repository Guidelines

This guide captures the expectations for contributors extending Afterflow’s privacy-first iOS app. Automation agents should also load `ai/README.md` for workflow- and tool-specific context.

## Project Structure & Module Organization
- `Afterflow/Models`, `Services`, `Views`, and `ViewModels` implement SwiftData entities, persistence, SwiftUI surfaces, and state layers respectively; keep new modules inside these folders so Swift Package targets remain predictable.
- `Resources/Assets.xcassets` holds app colors and icons; any additional assets or localized strings belong here.
- Tests split into `AfterflowTests/ModelTests`, `ServiceTests`, `ViewModelTests`, and `AfterflowUITests/`; mirror production folders when adding specs.
- Product requirements and UX notes live under `specs/00x-*`; update the matching spec before large feature work.

## Build, Test, and Development Commands
- `open Afterflow.xcodeproj` — launch Xcode; select the `Afterflow` scheme and iOS 17.6+ simulator.
- `xcodebuild build -scheme Afterflow -destination 'platform=iOS Simulator,name=iPhone 16'` — CI-friendly build to ensure code-signing and warnings pass.
- `xcodebuild test -scheme Afterflow -destination 'platform=iOS Simulator,name=iPhone 16'` — full XCTest + SwiftUI previews smoke run (same as `Cmd+U`).
- `xcodebuild test ... -only-testing:AfterflowTests/TherapeuticSessionTests` — example of targeting a focused suite during TDD loops.

## Coding Style & Naming Conventions
- Follow Swift API Design Guidelines: types `PascalCase`, properties/functions `camelCase`, constants prefixed with context (e.g., `sessionFetchRequest`).
- Use 4-space indentation and keep files under 300 lines; extract SwiftUI subviews into `Views/Components` when bodies exceed ~80 lines.
- Keep view models `Observable` structs/classes with clearly named `@Published` fields (`formState`, `validationErrors`); avoid single-letter abbreviations.
- Run Xcode’s “Re-Indent” or `Editor > Structure > Reformat` before committing; lint scripts are not enforced yet, so manual consistency matters.

## Testing Guidelines
- XCTest is the single framework; add unit tests beside source counterparts (e.g., `Models/TherapeuticSession.swift` pairs with `ModelTests/TherapeuticSessionTests.swift`).
- New code must maintain ≥80% coverage; prioritize behavior-driven method names (`testSavingDraftRestoresLastInput`).
- UI or performance regressions belong in `AfterflowUITests/`; create fixtures under `AfterflowTests/Resources` when stateful data is required.
- Always run `xcodebuild test -scheme Afterflow ...` on the latest simulator listed in README before opening a pull request.

## Commit & Pull Request Guidelines
- Match existing history: concise, present-tense subjects (`session tasks completed`, `clean up`) without prefixes; squash micro commits locally.
- Reference issues or specs in the body (`Specs: 002-spotify-integration`) and describe user value plus risk mitigations.
- PRs must include: summary, screenshots for UI changes, simulator/device target, testing checklist, and description of privacy implications (data touched, storage location).
- Tag reviewers who own the touched area (`Models`, `Services`, etc.) and confirm that `specs/` updates accompany any feature-level change.

## Security & Configuration Notes
- Treat all features as offline-first: no new network calls or third-party SDKs without explicit approval.
- Respect automatic code signing; if you must change bundle IDs or entitlements, document the rationale and reset to project defaults before merging.
- Sensitive data never leaves the device; confirm encryption or local-only storage in PR notes whenever persistence logic changes.
