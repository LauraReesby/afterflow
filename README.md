# Afterflow

*A private, offline-first iOS app for logging psychedelic-assisted therapy sessions*

## Overview

Afterflow is a therapeutic session logging app designed for individuals undergoing psychedelic-assisted therapy. It provides a safe, private space to record intentions, environment details, music, mood changes, and post-session reflections—all while maintaining complete privacy and working entirely offline.

### Key Features

- **🔒 Privacy-First**: All data stays on your device. No cloud sync, tracking, or external data collection
- **📱 Native iOS**: Built with SwiftUI and SwiftData for optimal performance on iPhone and iPad
- **🌐 Offline-First**: Core functionality works without internet connection
- **🎵 Spotify Integration**: Optional playlist linking (planned) for music context
- **📊 Mood Tracking**: Before and after session mood ratings with visual feedback
- **📝 Comprehensive Logging**: Capture treatment type, dosage, environment, intentions, and reflections
- **♿ Accessibility**: VoiceOver support and Dynamic Type compliance

### Therapeutic Value

Afterflow helps users:
- Track therapeutic progress over time
- Reflect on session experiences and insights
- Maintain detailed records for clinical discussions
- Understand patterns in mood and treatment response
- Export data for sharing with healthcare providers (planned)

## Screenshots

*Screenshots coming soon as UI development progresses*

## Requirements

- **iOS 17.6+** (iPhone and iPad)
- **Xcode 16.0+** for development
- **macOS 14.0+** for development environment

## Getting Started

### Clone the Repository

```bash
git clone https://github.com/LauraReesby/afterflow.git
cd afterflow
```

### Building the App

1. **Open in Xcode:**
   ```bash
   open Afterflow.xcodeproj
   ```

2. **Select Target Device:**
   - Choose your preferred simulator or connected device
   - Minimum deployment target: iOS 17.6

3. **Build the Project:**
   - Press `Cmd + B` to build
   - Or use Product → Build from menu

### Running the App

1. **In Simulator:**
   - Press `Cmd + R` to build and run
   - App will launch in iOS Simulator

2. **On Physical Device:**
   - Connect your iOS device via USB
   - Select your device from the scheme selector
   - Press `Cmd + R` to install and launch

### Development Signing

The app is configured for automatic code signing. If you encounter signing issues:

1. Select the Afterflow project in Xcode navigator
2. Go to "Signing & Capabilities" tab
3. Change the "Team" to your Apple Developer account
4. Update "Bundle Identifier" to a unique identifier

## Testing

Afterflow maintains high test coverage with comprehensive unit and UI tests.

### Running Tests

**All Tests:**
```bash
# Command line
xcodebuild test -scheme Afterflow -destination 'platform=iOS Simulator,name=iPhone 16'

# Or in Xcode: Cmd + U
```

**Specific Test Suites:**
```bash
# Model tests only
xcodebuild test -scheme Afterflow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AfterflowTests/TherapeuticSessionTests

# Service tests only  
xcodebuild test -scheme Afterflow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AfterflowTests/SessionDataServiceTests
```

### Test Coverage

Current test coverage includes:
- **Model Tests**: TherapeuticSession entity validation, computed properties, data management
- **Service Tests**: CRUD operations, auto-save, draft recovery, validation
- **UI Tests**: App launch, basic navigation
- **Performance Tests**: Large dataset handling

**Coverage Target**: 80% minimum (currently achieved)

### Test Categories

- **Unit Tests** (`AfterflowTests/`): Model and service layer testing
- **UI Tests** (`AfterflowUITests/`): User interface workflow testing
- **Performance Tests**: Data handling and app launch metrics

## Project Structure

```
Afterflow/
├── Models/                    # SwiftData entities
│   └── TherapeuticSession.swift
├── Services/                  # Data services
│   └── SessionDataService.swift
├── Views/                     # SwiftUI views (in development)
│   └── ContentView.swift
├── ViewModels/               # Observable state management (planned)
└── Assets.xcassets/          # App icons and colors

AfterflowTests/               # Test suites
├── ModelTests/
│   └── TherapeuticSessionTests.swift
├── ServiceTests/
│   └── SessionDataServiceTests.swift
└── AfterflowUITests.swift

specs/                        # Feature specifications
├── 001-core-session-logging/
├── 002-spotify-integration/
└── 003-data-export/
```

## Architecture

Afterflow follows a clean architecture pattern optimized for SwiftUI:

- **Models**: SwiftData entities for local persistence
- **Services**: Data access and business logic
- **Views**: SwiftUI user interface components  
- **ViewModels**: Observable state management (iOS 17+)

### Key Principles

1. **Privacy-First**: No external data transmission
2. **SwiftUI + SwiftData Native**: Modern Apple frameworks
3. **Offline-First**: Local-first data storage
4. **Test-Driven**: 80% minimum test coverage
5. **Therapeutic Value**: Every feature supports healing

## Development Roadmap

### ✅ Phase 1: Foundation (Complete)
- [x] Core data model (TherapeuticSession)
- [x] Persistence layer (SessionDataService)
- [x] Comprehensive test suite
- [x] Basic session list view

### 🚧 Phase 2: Session Form UI (In Progress)
- [ ] SessionFormView for creating/editing sessions
- [ ] Form validation and error handling
- [ ] Date and treatment type selection

### 📋 Phase 3: Enhanced UI Components (Planned)
- [ ] Environment and music input views
- [ ] Mood rating sliders with emoji feedback
- [ ] Session detail view with reflections
- [ ] Enhanced session list with filters

### 🎵 Phase 4: Spotify Integration (Planned)
- [ ] OAuth authentication (PKCE flow)
- [ ] Playlist metadata fetching
- [ ] Playlist selection and linking

### 📊 Phase 5: Data Export (Planned)
- [ ] CSV export for data analysis
- [ ] PDF reports for clinical sharing
- [ ] Filtering and date range selection

## Contributing

This is a personal therapeutic app project. While the code is public for transparency, direct contributions are not currently accepted. However, feedback and suggestions are welcome through Issues.

### Development Setup

1. **Constitutional Compliance**: All changes must align with privacy-first principles
2. **Test-Driven Development**: New features require accompanying tests
3. **Accessibility**: All UI components must support VoiceOver and Dynamic Type

## Privacy & Data

### Data Collection: None
Afterflow collects **zero** personal data. All information stays on your device.

### Data Storage
- **Local Only**: SwiftData with SQLite backing
- **Optional CloudKit**: User-controlled sync (planned)
- **No Analytics**: No usage tracking or crash reporting

### Data Export
- **User Controlled**: Export only when explicitly requested
- **Local Processing**: All export operations happen on-device
- **Secure Sharing**: Uses iOS standard sharing mechanisms

## Support

- **Issues**: Report bugs or request features via GitHub Issues
- **Documentation**: See `/specs` directory for detailed feature specifications
- **Development Status**: Check `DEVELOPMENT_STATUS.md` for current progress

## License

[License information to be added]

---

**Afterflow** - Supporting healing through thoughtful session reflection.

*Built with privacy, therapeutic value, and iOS excellence in mind.*