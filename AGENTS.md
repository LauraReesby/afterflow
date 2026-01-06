# Repository Guidelines

This guide captures the expectations for contributors extending Afterflow’s privacy-first iOS app. Automation agents should also load `.agent/README.md` for workflow- and tool-specific context.

## Project Structure & Module Organization
- `Afterflow/Models`, `Services`, `Views`, and `ViewModels` implement SwiftData entities, persistence, SwiftUI surfaces, and state layers respectively; keep new modules inside these folders so Swift Package targets remain predictable.
- `Resources/Assets.xcassets` holds app colors and icons; any additional assets or localized strings belong here.
- Product requirements and UX notes live in the project README; consult it before large feature work.

## Build, Test, and Development Commands
- `./Scripts/run-swiftformat.sh` — repository-wide SwiftFormat pass.
- `./Scripts/run-swiftlint.sh` — SwiftLint using `.swiftlint.yml`.
- `./Scripts/build-app.sh [--destination <value>]` — wraps `xcodebuild build`; omit `--destination` to let Xcode choose an available target or provide a simulator/device spec.
- `./Scripts/run-app.sh --destination 'platform=iOS Simulator,name=iPhone 16'` — build, install, and launch Afterflow in a specific simulator (override `--bundle-id`, `--device`, etc., as needed).
- `./Scripts/test-app.sh [--destination <value>]` — wraps `xcodebuild test`; provide `--destination 'id=<DEVICE-UDID>'` when running on hardware.
- `open Afterflow.xcodeproj` — launch Xcode; select the `Afterflow` scheme when debugging interactively.

## Coding Style & Naming Conventions
- Follow Swift API Design Guidelines: types `PascalCase`, properties/functions `camelCase`, constants prefixed with context (e.g., `sessionFetchRequest`).
- Use 4-space indentation and target files under ~300 lines (300-400 acceptable if cohesive; above 400 requires refactoring); extract SwiftUI subviews into `Views/Components` when bodies exceed ~80 lines.
- Large feature sections can be extracted to `Views/<ParentView>/` subdirectories (e.g., `SessionListSection.swift` in `Views/ContentView/`).
- Keep view models `Observable` structs/classes with clearly named `@Published` fields (`formState`, `validationErrors`); avoid single-letter abbreviations.
- **Follow established patterns** (see `.agent/globals/style_guide.md` for details):
  - Extract complex state to dedicated `@Observable` managers (e.g., `ExportState`, `ImportState`)
  - Create reusable view modifiers for repeated UI patterns (e.g., `ErrorAlertModifier`)
  - Use `DesignConstants` for all spacing, animation, and styling values
- Run Xcode's "Re-Indent" or `Editor > Structure > Reformat` before committing; SwiftFormat and SwiftLint enforce shared rules but manual cleanup keeps diffs readable.
- **CRITICAL: Zero Swift warnings required** — Enforce with:
  1. `./Scripts/run-swiftformat.sh` — format code
  2. `./Scripts/run-swiftlint.sh` — lint code (0 violations required)
  3. `xcodebuild build-for-testing -scheme Afterflow -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep "\.swift.*warning:"` — verify zero Swift warnings (must return empty)
  All three must pass cleanly before opening a pull request.

## Testing Guidelines
- **Swift Testing framework** is the standard: use `import Testing`, `@Test` attributes, and `#expect()` for assertions (not XCTest).
- Add unit tests beside source counterparts (e.g., `Models/TherapeuticSession.swift` pairs with `ModelTests/TherapeuticSessionTests.swift`).
- New code must maintain ≥80% coverage; prioritize descriptive function names (e.g., `func savingDraftRestoresLastInput()`).
- All test structs must be marked `@MainActor` when testing SwiftUI components.
- **Test code must build with zero Swift warnings**:
  - Fix unused variable warnings by replacing with `_` if truly unused
  - Change `var` to `let` for variables that never mutate
  - Verify test builds cleanly before committing
- UI or performance regressions belong in `AfterflowUITests/`; create fixtures under `AfterflowTests/Resources` when stateful data is required.
- Always run `xcodebuild test -scheme Afterflow ...` on the latest simulator listed in README before opening a pull request.

## Commit & Pull Request Guidelines
- Match existing history: concise, present-tense subjects (`session tasks completed`, `clean up`) without prefixes; squash micro commits locally.
- Tag reviewers who own the touched area (`Models`, `Services`, etc.).

## Security & Configuration Notes
- Treat all features as offline-first: no new network calls or third-party SDKs without explicit approval.
- Respect automatic code signing; if you must change bundle IDs or entitlements, document the rationale and reset to project defaults before merging.
- Sensitive data never leaves the device; confirm encryption or local-only storage in PR notes whenever persistence logic changes.
