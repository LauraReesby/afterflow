# Contributor Guide

Welcome to Afterflow! This guide helps human contributors understand the project and get started.

**For AI agents**: See `.agent/README.md` for complete guidance.

## Quick Start

1. **Clone and build**
   ```bash
   git clone <repo-url>
   cd afterflow
   open Afterflow.xcodeproj
   ```

2. **Run the app**
   ```bash
   ./Scripts/run-app.sh --destination 'platform=iOS Simulator,name=iPhone 16'
   ```

3. **Run tests**
   ```bash
   ./Scripts/test-app.sh --destination 'platform=iOS Simulator,name=iPhone 16'
   ```

## Project Overview

Afterflow is a **privacy-first, offline-first therapeutic session logging app** for iOS. Built with SwiftUI and SwiftData, it helps users track psychedelic-assisted therapy sessions with absolute privacy.

### Core Principles

1. **Privacy First**: All data stays on-device by default
2. **Offline First**: Core functionality works without internet
3. **Therapeutic Value**: Every feature serves healing and integration
4. **Native Excellence**: Premium iOS experience with SwiftUI/SwiftData

### Technology Stack

- SwiftUI for all interfaces
- SwiftData for local persistence
- Swift Testing framework for tests
- Minimum iOS 17.6

## Development Workflow

### Before You Commit

Run these checks in order (all must pass):

```bash
# 1. Format code
./Scripts/run-swiftformat.sh

# 2. Lint code (0 violations required)
./Scripts/run-swiftlint.sh

# 3. Verify zero Swift warnings (must return empty)
xcodebuild build-for-testing -scheme Afterflow \
  -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | \
  grep "\.swift.*warning:"

# 4. Run tests
./Scripts/test-app.sh --destination 'platform=iOS Simulator,name=iPhone 16'
```

### Code Style

- Follow Swift API Design Guidelines
- 4-space indentation
- Keep files under ~300 lines (400 max)
- Extract large SwiftUI views to components
- Use `DesignConstants` for all spacing/animation values

See `.agent/globals/style_guide.md` for detailed standards.

### Testing Requirements

- Write tests BEFORE implementation (Red-Green-Refactor)
- Minimum 80% code coverage
- 100% coverage for public APIs
- Use Swift Testing framework: `@Test`, `#expect()`
- Test structs must be `@MainActor` when testing SwiftUI

See `.agent/globals/style_guide.md` for testing patterns.

### Privacy & Security

- No cloud sync by default
- No external analytics or tracking
- No network calls without approval
- Never log therapeutic content
- Respect offline-first architecture

See `.agent/globals/constitution.md` for complete privacy requirements.

## Project Structure

```
Afterflow/
├── Models/           # SwiftData models
├── Views/            # SwiftUI views
│   └── Components/   # Reusable UI components
├── ViewModels/       # View state management
├── Services/         # Business logic
└── Utilities/        # Extensions and helpers

AfterflowTests/
├── ComponentTests/   # UI component tests
├── ViewModelTests/   # View model tests
├── IntegrationTests/ # Integration tests
└── Performance/      # Performance tests

.agent/               # AI agent guidance (also useful for humans!)
├── README.md         # Complete development guide
├── globals/          # Universal standards
├── agents/           # Agent-specific workflows
└── workflows/        # Implementation workflows
```

## Useful Scripts

All scripts are in the `Scripts/` directory:

```bash
# Build
./Scripts/build-app.sh

# Run in simulator
./Scripts/run-app.sh --destination 'platform=iOS Simulator,name=iPhone 16'

# Test
./Scripts/test-app.sh --destination 'platform=iOS Simulator,name=iPhone 16'

# Test specific suite
./Scripts/test-app.sh -only-testing:AfterflowTests/ModelTests

# Format
./Scripts/run-swiftformat.sh

# Lint
./Scripts/run-swiftlint.sh
```

## Common Patterns

### State Management
Extract complex state to `@Observable` classes:
```swift
@Observable
final class ExportState {
    var isExporting = false
    var exportError: String?
}
```

### View Modifiers
Create reusable modifiers for repeated patterns:
```swift
struct ErrorAlertModifier: ViewModifier { ... }
```

### Design Constants
Centralize magic numbers:
```swift
enum DesignConstants {
    enum Spacing {
        static let small: CGFloat = 8
    }
}
```

See `.agent/agents/ios_dev.md` for SwiftUI/SwiftData examples.

## Pull Request Guidelines

- Write clear, present-tense commit messages
- Reference related issues
- Include test coverage in PR description
- Ensure all quality checks pass
- Document privacy/offline impact if applicable

## Getting Help

- **Detailed Guidance**: See `.agent/` directory
- **Constitution**: `.agent/globals/constitution.md`
- **Style Guide**: `.agent/globals/style_guide.md`
- **iOS Workflows**: `.agent/agents/ios_dev.md`
- **Issues**: GitHub Issues

## License

See LICENSE file for details.

---

**For comprehensive guidance**, explore the `.agent/` directory — it contains everything you need to know about contributing to Afterflow.
