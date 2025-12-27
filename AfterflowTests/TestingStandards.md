# Afterflow Testing Standards

This document outlines the testing conventions and standards for the Afterflow iOS app test suite.

## Testing Framework

### Swift Testing (@Test) - REQUIRED for New Tests

All new tests MUST use the **Swift Testing** framework with the `@Test` macro.

**Why Swift Testing?**
- Modern, expressive syntax
- Better async/await support
- Cleaner test organization
- More descriptive test names
- Better compiler integration

**Example:**
```swift
import Testing
@testable import Afterflow

@MainActor
struct ExportStateTests {
    @Test("Export CSV completes successfully")
    func exportCSVSucceeds() async throws {
        // Arrange
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let exportState = try TestHelpers.makeExportState(sessionStore: store)
        let sessions = SessionFixtureFactory.makeSessions(count: 5)

        // Act
        exportState.startExport(sessions: sessions, with: ExportRequest(format: .csv))

        // Assert
        #expect(exportState.isExporting == true)
        #expect(exportState.exportDocument != nil)
    }
}
```

### XCTest - Legacy (DO NOT USE for New Tests)

Existing XCTest files should remain unchanged - **migration is not worth the effort**. However, all NEW test files MUST use Swift Testing.

**Legacy Example (DO NOT COPY):**
```swift
import XCTest
@testable import Afterflow

class LegacyTests: XCTestCase {
    func testSomething() {
        XCTAssertTrue(true)
    }
}
```

## Test Naming Conventions

### Test Method Names

Use descriptive names that clearly state **what is being tested** and **what the expected outcome is**.

**Format**: `test<Scenario><Expectation>()`

**Good Examples:**
- `testStartExportCSVSucceeds()` - Clear scenario and expectation
- `testImportErrorCapturedOnInvalidCSV()` - Clear error handling scenario
- `testFilteringTenThousandSessions()` - Clear performance scenario
- `testMarkedDatesNormalizedToMidnight()` - Clear data transformation

**Bad Examples:**
- `testExport()` - Too vague
- `testImport1()` - Unclear purpose
- `testCase()` - No context
- `test1()` - Meaningless

### Swift Testing Display Names

Use the `@Test("description")` attribute for clear test output:

```swift
@Test("Export CSV completes successfully")
func exportCSVSucceeds() async throws { }

@Test("Import error captured on invalid CSV")
func importErrorCapturedOnInvalidCSV() async throws { }
```

## Test Structure

### Arrange-Act-Assert Pattern

All tests should follow the AAA pattern:

```swift
@Test("Session list filters by treatment type")
func sessionListFiltersByTreatmentType() async throws {
    // Arrange - Set up test environment
    let sessions = SessionFixtureFactory.makeSessions(count: 10)
    var viewModel = TestHelpers.makeSessionListViewModel()
    viewModel.treatmentFilter = .psilocybin

    // Act - Perform the action being tested
    let filtered = viewModel.applyFilters(to: sessions)

    // Assert - Verify the outcome
    #expect(filtered.allSatisfy { $0.treatmentType == .psilocybin })
    #expect(filtered.count < sessions.count)
}
```

### Test Isolation

Each test must be completely isolated:
- Use in-memory ModelContainer for SwiftData tests
- Create fresh test environments per test
- Don't rely on test execution order
- Clean up resources in test teardown (if needed)

**Example:**
```swift
@Test("SessionStore creates session successfully")
func sessionStoreCreatesSession() async throws {
    // Create isolated test environment
    let (container, store) = try TestHelpers.makeTestEnvironment()

    // Test with fresh environment
    let session = SessionFixtureFactory.makeSessions(count: 1)[0]
    try store.create(session)

    // Verify without affecting other tests
    let fetched = try store.fetchAll()
    #expect(fetched.count == 1)
}
```

## Assertions

### Swift Testing Assertions

Use `#expect()` for Swift Testing assertions:

```swift
// Boolean checks
#expect(value == expectedValue)
#expect(collection.isEmpty)
#expect(optional != nil)

// Collection checks
#expect(array.count == 5)
#expect(array.contains(element))
#expect(array.allSatisfy { $0.isValid })

// Error checks
#expect(throws: CSVImportService.ImportError.self) {
    try importService.import(from: invalidURL)
}
```

### Better Assertions

**Prefer content verification over count checks:**

❌ **Bad:**
```swift
#expect(filtered.count == 1)
```

✅ **Good:**
```swift
#expect(filtered.count == 1)
#expect(filtered.first?.intention == "Expected intention")
#expect(filtered.first?.id == expectedSession.id)
```

**Verify error messages, not just error types:**

❌ **Bad:**
```swift
#expect(throws: Error.self) {
    try doSomething()
}
```

✅ **Good:**
```swift
do {
    try doSomething()
    Issue.record("Expected error to be thrown")
} catch let error as CustomError {
    #expect(error.localizedDescription.contains("expected message"))
}
```

## Test Fixtures and Helpers

### Use Factory Methods

Always use factory methods from `SessionFixtureFactory` and `ErrorFixtureFactory`:

```swift
// Sessions
let sessions = SessionFixtureFactory.makeSessions(count: 10)
let sessionWithReminder = SessionFixtureFactory.makeSessionWithReminder()
let calendarSessions = SessionFixtureFactory.makeSessionsForCalendar(monthCount: 3)
let edgeCaseSessions = SessionFixtureFactory.makeSessionsWithEdgeCases()

// Errors
let csvError = ErrorFixtureFactory.makeInvalidHeaderError()
let fileError = ErrorFixtureFactory.makeFileNotFoundError()
```

### Use Test Helpers

Use `TestHelpers` for creating test environments:

```swift
// Test environment
let (container, store) = try TestHelpers.makeTestEnvironment()

// View models
let exportState = try TestHelpers.makeExportState(sessionStore: store)
let importState = try TestHelpers.makeImportState(sessionStore: store)
let listViewModel = TestHelpers.makeSessionListViewModel(searchText: "query")

// Dates
let fixedDate = TestHelpers.fixedDate()
let monthStart = TestHelpers.monthStart(for: Date())
let customDate = TestHelpers.dateComponents(year: 2024, month: 12, day: 1)
```

## Async Testing

### Proper Async/Await Usage

Use `async throws` for tests that need async operations:

```swift
@Test("Export state completes async export")
func exportStateCompletesAsyncExport() async throws {
    let exportState = try TestHelpers.makeExportState()
    let sessions = SessionFixtureFactory.makeSessions(count: 5)

    exportState.startExport(sessions: sessions, with: ExportRequest(format: .csv))

    // Wait for async operation to complete
    try await TestHelpers.waitFor { exportState.exportDocument != nil }

    #expect(exportState.isExporting == false)
    #expect(exportState.exportDocument != nil)
}
```

### Task Cancellation Testing

Test cancellation properly:

```swift
@Test("Export cancellation stops task")
func exportCancellationStopsTask() async throws {
    let exportState = try TestHelpers.makeExportState()
    let sessions = SessionFixtureFactory.makeSessions(count: 1000)

    exportState.startExport(sessions: sessions, with: ExportRequest(format: .pdf))
    exportState.cancelExport()

    try await Task.sleep(nanoseconds: 100_000_000) // 0.1s

    #expect(exportState.isExporting == false)
    #expect(exportState.exportError == nil)
}
```

## Edge Cases and Boundary Testing

### Always Test Edge Cases

Every test file should include edge case tests:

```swift
@Test("Filtering handles empty sessions")
func filteringHandlesEmptySessions() async throws {
    let viewModel = TestHelpers.makeSessionListViewModel()
    let filtered = viewModel.applyFilters(to: [])
    #expect(filtered.isEmpty)
}

@Test("Mood rating clamps to valid range")
func moodRatingClampsToValidRange() async throws {
    let scale = MoodRatingScale()
    #expect(scale.emoji(for: 0) == scale.emoji(for: 1))   // Below min
    #expect(scale.emoji(for: 11) == scale.emoji(for: 10)) // Above max
}
```

### Boundary Value Testing

Test boundary values systematically:

```swift
@Test("Mood values at boundaries")
func moodValuesAtBoundaries() async throws {
    // Minimum
    #expect(MoodRatingScale.descriptor(for: 1) == "Terrible")

    // Maximum
    #expect(MoodRatingScale.descriptor(for: 10) == "Amazing")

    // Below minimum (if applicable)
    // Above maximum (if applicable)
}
```

## Performance Testing

### Use XCTest Metrics for Performance

Performance tests should use XCTest's measure API:

```swift
func testFilteringLargeDataset() {
    let sessions = SessionFixtureFactory.makeSessions(count: 10_000)
    var viewModel = SessionListViewModel()

    measure {
        let _ = viewModel.applyFilters(to: sessions)
    }
}
```

### Document Performance Expectations

Always document expected performance:

```swift
@Test("CSV export completes in under 2 seconds for 5000 sessions")
func csvExportPerformance() async throws {
    let sessions = SessionFixtureFactory.makeSessions(count: 5000)
    let exportService = CSVExportService()

    let start = Date()
    let _ = try exportService.export(sessions: sessions, dateRange: nil, treatmentType: nil)
    let duration = Date().timeIntervalSince(start)

    #expect(duration < 2.0, "Export took \(duration)s, expected < 2.0s")
}
```

## File Organization

### Test File Naming

Test files should mirror production file structure:

| Production File | Test File |
|----------------|-----------|
| `Afterflow/ViewModels/ExportState.swift` | `AfterflowTests/ViewModelTests/ExportStateTests.swift` |
| `Afterflow/Services/CSVExportService.swift` | `AfterflowTests/ServiceTests/CSVExportServiceTests.swift` |
| `Afterflow/Views/Components/FilterMenu.swift` | `AfterflowTests/ComponentTests/FilterMenuTests.swift` |

### Test Directory Structure

```
AfterflowTests/
├── Helpers/
│   ├── TestHelpers.swift
│   ├── SessionFixtureFactory.swift
│   └── ErrorFixtureFactory.swift
├── ModelTests/
│   └── TherapeuticSessionTests.swift
├── ViewModelTests/
│   ├── ExportStateTests.swift
│   ├── ImportStateTests.swift
│   └── SessionListViewModelTests.swift
├── ServiceTests/
│   ├── SessionStoreTests.swift
│   ├── CSVExportServiceTests.swift
│   └── CSVImportServiceTests.swift
├── ViewTests/
│   └── CollapsibleCalendarViewTests.swift
├── ComponentTests/
│   ├── FilterMenuTests.swift
│   ├── MoodRatingViewTests.swift
│   └── FullWidthSearchBarTests.swift
├── ModifierTests/
│   └── ViewModifierTests.swift
├── Performance/
│   └── SessionListPerformanceTests.swift
└── IntegrationTests/
    └── ExportImportIntegrationTests.swift
```

## Coverage Goals

### Minimum Coverage Targets

- **Overall Project**: 80% minimum
- **New Features**: 100% coverage required
- **ViewModels**: 90% minimum
- **Services**: 90% minimum
- **Models**: 95% minimum
- **Views/Components**: 75% minimum (UI tests supplement)

### What to Test

**Required:**
- ✅ All public methods
- ✅ All error paths
- ✅ All edge cases (empty, null, boundary values)
- ✅ All async operations
- ✅ All state transitions

**Optional:**
- Internal helper methods (if complex)
- Private methods (via public interface testing)

## Best Practices Summary

1. ✅ Use Swift Testing (@Test) for all new tests
2. ✅ Follow Arrange-Act-Assert pattern
3. ✅ Use descriptive test names
4. ✅ Test edge cases and boundaries
5. ✅ Verify content, not just counts
6. ✅ Use test helpers and fixtures
7. ✅ Isolate tests completely
8. ✅ Document performance expectations
9. ✅ Test error handling thoroughly
10. ✅ Maintain 80%+ coverage

## References

- [Swift Testing Documentation](https://developer.apple.com/documentation/testing)
- [XCTest Documentation](https://developer.apple.com/documentation/xctest) (legacy only)
- [Afterflow Test Plan](/Users/laurareesby/.claude/plans/dazzling-exploring-tiger.md)
