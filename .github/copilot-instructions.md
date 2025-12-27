# Afterflow — AI Development Instructions

## Project Overview

Afterflow is a **privacy-first therapeutic session logging iOS app** for psychedelic-assisted therapy. Built with SwiftUI + SwiftData, it enables secure offline reflection and session tracking while maintaining complete user data control.

### Constitutional Principles (NON-NEGOTIABLE)
1. **Privacy-First**: All data local by default, no tracking, user controls all sharing
2. **SwiftUI + SwiftData Native**: Modern Apple frameworks only  
3. **Therapeutic Value-First**: Every feature supports healing/reflection
4. **Offline-First**: Core functionality works without internet
5. **Simplicity**: Essential therapeutic features only, avoid feature creep
6. **Test-Driven Quality**: 80% coverage minimum, TDD required

## Architecture Patterns

### SwiftData Model Pattern
```swift
@Model
final class TherapeuticSession {
    // Enum storage uses raw string values with computed properties
    internal var treatmentTypeRawValue: String
    var treatmentType: PsychedelicTreatmentType {
        get { PsychedelicTreatmentType(rawValue: treatmentTypeRawValue) ?? .psilocybin }
        set { treatmentTypeRawValue = newValue.rawValue }
    }
    
    func markAsUpdated() { self.updatedAt = Date() }
}
```

### Service Layer with Auto-Save
```swift
@Observable
class SessionDataService {
    private let modelContext: ModelContext
    private var autoSaveTimer: Timer? // 5-second auto-save
    
    // CRUD operations throw errors, don't return optionals
    func createSession(_ session: TherapeuticSession) throws {
        modelContext.insert(session)
        markUnsavedChanges()
        try saveContext()
    }
}
```

### SwiftUI Views with Environment
```swift
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [TherapeuticSession]
    
    // Use @Query for data fetching, not manual service calls
}
```

## Testing Requirements

### Test-Driven Development (MANDATORY)
- **Red-Green-Refactor** sequence for all public interfaces
- **80% minimum coverage** before feature merge  
- **100% public API coverage** required
- Use Swift Testing framework (`import Testing`, `@Test`)

### Test Environment Setup
```swift
@MainActor
func createTestEnvironment() -> (ModelContainer, SessionDataService) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TherapeuticSession.self, configurations: config)
    let service = SessionDataService(modelContext: container.mainContext)
    return (container, service)
}
```

### Test Patterns
- **Models**: Validation, computed properties, enum conversion
- **Services**: CRUD operations, error handling, auto-save recovery
- **Views**: Navigation, form validation, accessibility
- **Integration**: SwiftData persistence, draft recovery

## Development Workflow

### File Organization
```
Afterflow/
├── Models/                 # SwiftData entities (TherapeuticSession.swift)
├── Services/              # Data layer (SessionDataService.swift) 
├── Views/                 # SwiftUI components
├── ViewModels/           # Observable state (@Observable classes)
└── Resources/            # Assets, storyboards, and resources
    ├── Assets.xcassets/  # App icons, colors
    └── LaunchScreen.storyboard

AfterflowTests/
├── ModelTests/           # Entity validation, computed properties
├── ServiceTests/         # CRUD, auto-save, data persistence  
├── ViewModelTests/       # State management, validation
└── IntegrationTests/     # Cross-layer workflows
```

### Task Management
- Tasks tracked in the project README or relevant issues.
- Mark complete (✅) only after: Code + Tests + Coverage + Functionality verified
- Use descriptive commit messages: `feat(session): add mood slider`

### Commit Convention
```
feat(models): add mood change computed property
test(services): increase SessionDataService coverage to 85%
fix(ui): resolve VoiceOver accessibility in session form
refactor(views): extract reusable form validation components
```

## Key Implementation Details

### Mood Rating System
- Integer scale 1-10 (not 0-based)
- Validation in both model and service layers
- Computed `moodChange` property for before/after difference

### Spotify Integration (Planned)
- **OAuth PKCE flow only** — no client secrets, no in-app playback
- Store metadata only: `spotifyPlaylistURI`, `spotifyPlaylistName`, `spotifyPlaylistImageURL`
- Graceful degradation when API unavailable
- User can clear connection: `clearSpotifyData()` method

### Auto-Save & Draft Recovery
- 5-second auto-save timer in `SessionDataService`
- Draft recovery using UserDefaults for session ID tracking
- 24-hour expiry for draft recovery
- Background save when app enters background

### Error Handling
- Services throw errors, don't return optionals: `func createSession(_:) throws`
- Use Result types for async operations: `async -> Result<Void, SessionError>`
- Validation returns string arrays: `validateSession(_:) -> [String]`

## Privacy & Therapeutic Focus

### Data Handling
- **Never log therapeutic data** in debug output
- **Local-first**: SwiftData with SQLite backing, optional CloudKit
- **Export control**: CSV/PDF generation user-initiated only
- **Biometric protection**: Encourage but don't require Face ID/Touch ID

### UI Guidelines
- **Tone**: Reflective, neutral, non-clinical language
- **Accessibility**: VoiceOver labels, Dynamic Type support required
- **Calming design**: Avoid dark patterns, gamification
- **Therapeutic value**: Each feature must support healing/reflection

### Development Constraints
- **No analytics/tracking** — respect vulnerable user data
- **No external API calls** in core features (Spotify is optional)
- **Graceful offline** — all CRUD operations work without internet
- **iOS 17.6+ minimum** — use modern SwiftUI/SwiftData capabilities

## When Working on Features

1. **Check constitutional compliance** against all 6 principles
2. **Read relevant documentation** in the project README or issues
3. **Write tests first** before implementation (TDD)
4. **Use existing patterns** from Models/Services layers
5. **Verify 80% coverage** after changes
6. **Test therapeutic value** — does this support healing?

## Common Pitfalls to Avoid
- Don't modify enum raw values after data exists (breaking change)
- Don't implement public methods without corresponding tests
- Don't add external dependencies without constitutional review  
- Don't expose therapeutic data in logs or debug output
- Don't create features that could encourage substance misuse
- Don't break offline functionality for optional features