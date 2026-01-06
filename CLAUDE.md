# afterflow Development Guidelines

**⚠️ IMPORTANT: This document references the authoritative guidelines in `AGENTS.md` and `.agent/` directory.**

For complete development guidance, consult:
- **`AGENTS.md`** — Primary contributor guidelines, build commands, coding style
- **`.agent/README.md`** — AI agent control center with links to all guidance documents
- **`.agent/globals/constitution.md`** — Core principles (privacy, testing, therapeutic value)
- **`.agent/globals/style_guide.md`** — Detailed Swift/SwiftUI coding standards
- **`.agent/agents/ios_dev.md`** — iOS development workflow and checklists

Last updated: 2026-01-06

## Active Technologies

- SwiftUI for iOS app development
- Swift Testing framework (`@Test`, `#expect`) for unit tests
- SwiftData for data persistence
- NavigationSplitView for adaptive layouts

## Project Structure

See `AGENTS.md` for complete module organization. Key directories:

```text
Afterflow/
  ├── Models/               # Data models and business logic
  ├── Views/                # SwiftUI views and components
  ├── ViewModels/           # View state and logic
  ├── Services/             # API, storage, and export services
  └── Utilities/            # Extensions and helpers
AfterflowTests/
  ├── ComponentTests/       # UI component tests
  ├── ViewModelTests/       # View model tests
  ├── IntegrationTests/     # Integration tests
  └── Performance/          # Performance tests
```

## Quick Reference

**See `AGENTS.md` and `.agent/agents/ios_dev.md` for complete commands and workflows.**

### Pre-Commit Quality Checks (MANDATORY)

Run these commands **in order** before every commit:

```bash
# 1. Format code
./Scripts/run-swiftformat.sh

# 2. Lint code (must show 0 violations)
./Scripts/run-swiftlint.sh

# 3. Verify zero Swift warnings (must return empty)
xcodebuild build-for-testing -scheme Afterflow -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep "\.swift.*warning:"

# 4. Run tests
./Scripts/test-app.sh --destination 'platform=iOS Simulator,name=iPhone 16'
```

All four checks must pass cleanly.

### Build Commands

See `AGENTS.md` § "Build, Test, and Development Commands" for:
- `./Scripts/build-app.sh` — Build app
- `./Scripts/run-app.sh` — Run in simulator
- `./Scripts/test-app.sh` — Run tests

## Key Guidelines Summary

**Full details in `.agent/globals/style_guide.md` and `AGENTS.md`.**

### Code Style (see `.agent/globals/style_guide.md`)
- Swift API Design Guidelines (PascalCase types, camelCase members)
- 4-space indentation, files < 300 lines target
- **Zero Swift warnings required** (app + tests)
- Extract complex state to `@Observable` managers
- Use `DesignConstants` for all magic numbers

### Testing (see `.agent/globals/style_guide.md` § "Testing Standards")
- Swift Testing framework: `@Test`, `#expect()`, `@MainActor`
- ≥80% coverage required
- **Test code must build with zero warnings**
- Descriptive function names (e.g., `func sessionSavingRestoresLastInput()`)

### Privacy & Offline (see `.agent/globals/constitution.md`)
- All data stays on-device by default
- No network calls without approval
- Maintain offline-first functionality

## Recent Changes

- 2026-01-06: Added mandatory Swift warning verification for app and tests
- 2026-01-06: Added pill-shaped search control bar with glass effect
- 2026-01-06: Refactored NavigationSplitView for iPad split screen support
- 2026-01-06: Removed SessionListViewModel caching (non-mutating filters)
- 2026-01-06: Fixed all test build warnings (zero warnings achieved)
- 999-test-consolidation: Added

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
