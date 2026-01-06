# Shared Style Guide

Applies to every agent touching Swift, Markdown, or automation scripts. Supplements the language-specific guides already embedded in `AGENTS.md` and `.github/copilot/afterflow-agent.md`.

## Swift & SwiftUI
- Use Swift API Design Guidelines: `PascalCase` types, `camelCase` members, descriptive argument labels.
- Indent with **4 spaces**; avoid tabs.
- Keep Swift files under ~300 lines as a target—extract helpers or subviews when bodies exceed ~80 lines. Files between 300-400 lines are acceptable if they're cohesive and follow Single Responsibility Principle. Above 400 lines requires refactoring.
- SwiftUI subviews live in `Afterflow/Views/Components` and adopt `PreviewProvider` stubs gated by `#if DEBUG` when useful.
- Large feature sections can be extracted to `Afterflow/Views/<ParentView>/` (e.g., `Views/ContentView/SessionListSection.swift`).
- View models must be `@Observable` or `ObservableObject` with clearly named `@Published` state.
- Services throw strongly typed errors; prefer `Result` for async call sites.

### Established Patterns (Dec 2024)
- **State Management**: Extract complex state into dedicated `@Observable` classes (see `ExportState.swift`, `ImportState.swift`) rather than scattering `@State` variables across views.
- **Reusable Modifiers**: Create view modifiers for repeated patterns (see `ErrorAlertModifier.swift`, `ExportFlowsModifier.swift`) to reduce duplication.
- **Design Constants**: Centralize magic numbers in `DesignConstants.swift` with nested enums (`Animation`, `Spacing`, `Shadow`, etc.).
- **Component Extraction**: When views exceed ~80 lines, extract to `Views/Components/` (e.g., `FullWidthSearchBar.swift`, `FilterMenu.swift`, `SessionRowView.swift`).

## SwiftFormat & SwiftLint
- SwiftFormat config lives in `.swiftformat`; run `./Scripts/run-swiftformat.sh` before committing.
- SwiftLint config lives in `.swiftlint.yml`; run `./Scripts/run-swiftlint.sh` after formatting (CI uses the same settings).
- Fix or document every violation—prefer refactoring over disabling rules inline.
- When formatting or linting adds effort, update the corresponding configuration in the same change so the rule set stays versioned with the code.
- **CRITICAL: Zero Swift warnings required for both app and test targets**
  - After formatting and linting, verify with: `xcodebuild build-for-testing -scheme Afterflow -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep "\.swift.*warning:"`
  - Expected output: (empty) — no Swift code warnings allowed
  - System warnings (e.g., `appintentsmetadataprocessor`) are acceptable
  - Fix unused variable warnings by replacing with `_` if truly unused
  - Change `var` to `let` for variables that never mutate

## Documentation & Comments
- Prefer expressive naming over comments; add a short comment only before non-obvious logic (e.g., privacy-sensitive persistence, data migrations).

## Testing Standards
- Unit tests use the **Swift Testing framework** (`import Testing`, `@Test`, `#expect`) and should run headlessly via `xcodebuild test -scheme Afterflow -destination 'platform=iOS Simulator,name=iPhone 16'`.
- Mirror production folders: `Afterflow/Models/Foo.swift` ↔ `AfterflowTests/ModelTests/FooTests.swift`.
- Tests follow descriptive function naming (e.g., `func sessionSavingRestoresLastInput()`) with `@Test` attribute; use `#expect()` for assertions.
- All test structs must be marked `@MainActor` when testing SwiftUI components.
- Tests always start with a failing case (Red-Green-Refactor).
- Maintain ≥80% coverage overall and 100% for any new public API; capture coverage stats in the PR body.
- **Test code must build with zero Swift warnings** — fix unused variables with `_`, change `var` to `let` when values don't mutate.
- Use the in-memory `ModelContainer` scaffold when testing SwiftData interactions:
  ```swift
  @MainActor
  func makeTestEnvironment() -> (ModelContainer, SessionStore) {
      let config = ModelConfiguration(isStoredInMemoryOnly: true)
      let container = try! ModelContainer(for: TherapeuticSession.self, configurations: config)
      let store = SessionStore(modelContext: container.mainContext, owningContainer: container)
      return (container, store)
  }
  ```
- UI and accessibility flows rely on XCUITest (`AfterflowUITests/`); snapshot VoiceOver + Dynamic Type tests must meet the project's accessibility standards.

## Markdown & Docs
- Headings use sentence case (`## Project structure`).
- Keep instructions concise (200–400 words when possible) with actionable bullets and inline code fences for commands.
- Link to files relative to repo root to keep references portable between tools.

## Privacy Defaults
- Never log therapeutic session contents or user-identifying data.
- Do not introduce network calls without explicit approval; when unavoidable, document endpoints and data contracts in the PR checklist.

## Performance & Accessibility Targets
- Constitutional baseline: launch < 2 s, main-thread I/O < 16 ms, workflows usable offline.
- Performance goals must be honored (e.g., session creation ≤ 60 s, Spotify connect ≤ 15 s, CSV export 1k sessions ≤ 2 s, PDF export 25 sessions ≤ 4 s); include measurements or rationale in PRs.
- Every major phase concludes with “Constitutional QA verification” (accessibility, performance profiling, privacy compliance); ensure these checks are documented before marking tasks complete.
