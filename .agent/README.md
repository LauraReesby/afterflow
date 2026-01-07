# AI Agent Control Center

**SINGLE SOURCE OF TRUTH** for all AI agents working in Afterflow. Load this document first—it contains everything you need to get started and links to all detailed guidance.

## Quick Start (Essential Reading)

1. **Read the Constitution** (`.agent/globals/constitution.md`) — Non-negotiable privacy, testing, and therapeutic value principles
2. **Review the Style Guide** (`.agent/globals/style_guide.md`) — All coding standards, patterns, and quality requirements
3. **Check iOS Development Workflow** (`.agent/agents/ios_dev.md`) — SwiftUI/SwiftData-specific guidance and checklists

## Project Overview

**Afterflow** is a **privacy-first, offline-first therapeutic session logging app** for individuals undergoing psychedelic-assisted therapy.

### Core Pillars
1. **Absolute Privacy**: No cloud sync, no tracking, no external data collection. Data belongs solely to the user.
2. **Therapeutic Value**: Every feature must serve the user's healing and integration process.
3. **Native Excellence**: Built with SwiftUI and SwiftData for a premium, reliable iOS experience.
4. **Offline Reliability**: Core functionality must work without an internet connection.

### Active Technologies
- SwiftUI for iOS app development
- Swift Testing framework (`@Test`, `#expect`) for unit tests
- SwiftData for data persistence
- NavigationSplitView for adaptive layouts

## Project Structure

```
Afterflow/
├── Models/               # Data models and business logic
├── Views/                # SwiftUI views and components
│   └── Components/       # Reusable UI components
├── ViewModels/           # View state and logic
├── Services/             # API, storage, and export services
└── Utilities/            # Extensions and helpers

AfterflowTests/
├── ComponentTests/       # UI component tests
├── ViewModelTests/       # View model tests
├── IntegrationTests/     # Integration tests
└── Performance/          # Performance tests

.agent/
├── README.md             # This file (AI entry point)
├── globals/              # Universal standards
│   ├── constitution.md
│   ├── style_guide.md
│   └── branching_strategy.md
├── agents/               # Agent-specific workflows
│   ├── ios_dev.md
│   └── backend.md
└── workflows/            # Implementation workflows
    ├── feature_implementation.md
    └── bugfix_flow.md
```

## Build & Test Commands

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

**All four checks must pass cleanly.**

### Development Commands

```bash
# Build app
./Scripts/build-app.sh [--destination <value>]

# Run app in simulator
./Scripts/run-app.sh --destination 'platform=iOS Simulator,name=iPhone 16'

# Run tests
./Scripts/test-app.sh [--destination <value>]

# Run specific test
./Scripts/test-app.sh --destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AfterflowTests/ModelTests

# Open in Xcode
open Afterflow.xcodeproj
```

## Critical Requirements

### Zero Swift Warnings Policy
- **Both app and test targets must build with zero Swift warnings**
- System warnings (e.g., `appintentsmetadataprocessor`) are acceptable
- Fix unused variables with `_`, change `var` to `let` when values don't mutate
- Verify with: `xcodebuild build-for-testing ... 2>&1 | grep "\.swift.*warning:"` (must return empty)

### Test-Driven Development
- Write tests BEFORE implementation (Red-Green-Refactor)
- Minimum 80% code coverage required
- 100% coverage for all public APIs
- Use Swift Testing framework: `@Test`, `#expect()`, `@MainActor`
- All test structs must be `@MainActor` when testing SwiftUI components

### Privacy & Offline First
- All data stays on-device by default
- No network calls without explicit approval
- Core functionality must work offline
- Never log therapeutic session contents or user-identifying data

## Detailed Guidance Map

| Topic | File | Description |
|-------|------|-------------|
| **Privacy, Testing, Values** | `.agent/globals/constitution.md` | Non-negotiable core principles |
| **Coding Standards** | `.agent/globals/style_guide.md` | All Swift/SwiftUI patterns, formatting, testing |
| **iOS Development** | `.agent/agents/ios_dev.md` | SwiftUI/SwiftData workflow & checklist |
| **Feature Implementation** | `.agent/workflows/feature_implementation.md` | Step-by-step feature workflow |
| **Bugfix Flow** | `.agent/workflows/bugfix_flow.md` | Hotfix workflow |
| **Branching Strategy** | `.agent/globals/branching_strategy.md` | Git workflow & PR expectations |
| **Human Contributors** | `AGENTS.md` | Lightweight guide for human developers |

## Workflow Checklist

Before marking any task complete, verify:

- [ ] Constitution principles honored (privacy, therapeutic value, offline-first)
- [ ] Code formatted (`./Scripts/run-swiftformat.sh`)
- [ ] Code linted with 0 violations (`./Scripts/run-swiftlint.sh`)
- [ ] Zero Swift warnings verified (app + tests)
- [ ] Tests written before implementation
- [ ] All tests pass (`./Scripts/test-app.sh`)
- [ ] Coverage maintained ≥80%
- [ ] Changes documented in commit message

## Common Patterns

### State Management
Extract complex state into dedicated `@Observable` classes:
```swift
@Observable
final class ExportState {
    var isExporting = false
    var exportError: String?
    // ...
}
```

### View Modifiers
Create reusable modifiers for repeated UI patterns:
```swift
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: String?
    // ...
}
```

### Design Constants
Centralize all magic numbers:
```swift
enum DesignConstants {
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
    }
}
```

## External Resources

- **GitHub Copilot Config**: `.github/copilot/afterflow-agent.md`
- **Copilot Commands**: `.github/copilot/slash-commands.md`
- **Project README**: `README.md` (user-facing documentation)

---

**Last Updated**: 2026-01-07
**Maintainer**: Afterflow Development Team
