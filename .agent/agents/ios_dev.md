# iOS Development Agent

**Role**: Expert SwiftUI + SwiftData engineer for Afterflow

**Prerequisites**: Read `.agent/README.md` first for complete guidance. This file contains iOS-specific workflow notes only.

## Quick Reference

All detailed standards are in the global guides:
- **Constitution**: `.agent/globals/constitution.md`
- **Style Guide**: `.agent/globals/style_guide.md` (includes all Swift/SwiftUI patterns)
- **Quality Checks**: `.agent/README.md` (pre-commit commands)

## iOS-Specific Workflow

### Before Starting Any Work

1. **Understand the Context**
   - Read the GitHub issue or user request
   - Review related files in the codebase
   - Check existing patterns in similar features

2. **Plan Your Changes**
   - List files you'll modify
   - Identify tests you'll write/update
   - Note any privacy or offline implications

### During Implementation

1. **Write Tests First** (Red-Green-Refactor)
   ```swift
   @Test @MainActor
   func sessionCreationPersistsData() {
       let (container, store) = makeTestEnvironment()
       // Test implementation
       #expect(store.sessions.count == 1)
   }
   ```

2. **Follow Established Patterns**
   - Extract complex state → `@Observable` classes
   - Repeated UI patterns → View modifiers
   - Magic numbers → `DesignConstants`
   - Large views → Extract to `Views/Components/`

3. **Keep Files Organized**
   - Models → `Afterflow/Models/`
   - Views → `Afterflow/Views/` (or `Views/Components/`)
   - ViewModels → `Afterflow/ViewModels/`
   - Tests → `AfterflowTests/<Category>Tests/`

### Before Committing

Run quality checks in this exact order:

```bash
# 1. Format
./Scripts/run-swiftformat.sh

# 2. Lint (must show 0 violations)
./Scripts/run-swiftlint.sh

# 3. Verify zero Swift warnings (must return empty)
xcodebuild build-for-testing -scheme Afterflow \
  -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | \
  grep "\.swift.*warning:"

# 4. Run tests
./Scripts/test-app.sh --destination 'platform=iOS Simulator,name=iPhone 16'
```

All four must pass before committing.

## Common SwiftUI/SwiftData Patterns

### In-Memory Test Environment

```swift
@MainActor
func makeTestEnvironment() -> (ModelContainer, SessionStore) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: TherapeuticSession.self,
        configurations: config
    )
    let store = SessionStore(
        modelContext: container.mainContext,
        owningContainer: container
    )
    return (container, store)
}
```

### View Model Pattern

```swift
@Observable
final class SessionFormViewModel {
    var intention: String = ""
    var validationErrors: [String] = []
    var isValid: Bool { validationErrors.isEmpty }

    func validate() {
        validationErrors.removeAll()
        if intention.trimmingCharacters(in: .whitespaces).isEmpty {
            validationErrors.append("Intention is required")
        }
    }
}
```

### Reusable View Modifier

```swift
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: String?

    func body(content: Content) -> some View {
        content.alert(
            "Error",
            isPresented: .constant(error != nil),
            presenting: error
        ) { _ in
            Button("OK") { error = nil }
        } message: { errorMessage in
            Text(errorMessage)
        }
    }
}

extension View {
    func errorAlert(title: String = "Error", error: Binding<String?>) -> some View {
        modifier(ErrorAlertModifier(error: error))
    }
}
```

## Pre-Commit Checklist

- [ ] Constitution reviewed (privacy, therapeutic value, offline-first)
- [ ] Tests written before implementation
- [ ] Code formatted (`./Scripts/run-swiftformat.sh`)
- [ ] Code linted with 0 violations (`./Scripts/run-swiftlint.sh`)
- [ ] Zero Swift warnings verified (app + tests)
- [ ] All tests pass (`./Scripts/test-app.sh`)
- [ ] Coverage ≥80% maintained
- [ ] Privacy/offline impact noted (if applicable)
- [ ] Commit message is descriptive

## Troubleshooting

### Tests Failing
- Run specific test: `./Scripts/test-app.sh -only-testing:AfterflowTests/ModelTests/TherapeuticSessionTests`
- Check test environment setup
- Verify `@MainActor` on test structs testing SwiftUI

### Build Warnings
- Check for unused variables (replace with `_`)
- Change `var` to `let` for values that don't mutate
- Fix implicit optionals and force unwraps

### SwiftLint Violations
- Review `.swiftlint.yml` for rule configuration
- Fix violations or document why they're necessary
- Prefer refactoring over inline rule disabling

---

**For complete guidance**, always refer to:
- `.agent/README.md` — AI Control Center
- `.agent/globals/style_guide.md` — All coding standards
- `.agent/globals/constitution.md` — Core principles
