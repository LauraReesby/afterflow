# Afterflow

[![CI](https://github.com/LauraReesby/afterflow/actions/workflows/ci.yml/badge.svg)](https://github.com/LauraReesby/afterflow/actions/workflows/ci.yml)
[![SwiftLint](https://github.com/LauraReesby/afterflow/actions/workflows/swiftlint.yml/badge.svg)](https://github.com/LauraReesby/afterflow/actions/workflows/swiftlint.yml)
[![SwiftFormat](https://github.com/LauraReesby/afterflow/actions/workflows/swiftformat.yml/badge.svg)](https://github.com/LauraReesby/afterflow/actions/workflows/swiftformat.yml)

A private, offline-first iOS app for logging psychedelic-assisted therapy sessions

## Overview

Afterflow is a therapeutic session logging app designed for individuals undergoing psychedelic-assisted therapy. It provides a safe, private space to record intentions, mood changes, and post-session reflections—all while maintaining complete privacy and working entirely offline.

### Key Features

- **📊 Mood Tracking**: Before and after session mood on a tappable ten-step scale; the after-mood stays "not recorded" until you actually log it
- **📝 Comprehensive Logging**: Capture treatment type, intentions, and reflections (editable later in Session Detail)
- **🪞 Reflection Entry**: A dedicated screen for settling in after a session — mood-now scale, gentle writing prompts, and free text
- **📈 Trends**: On-device mood-over-time chart, stat tiles, lift by treatment, and recurring words from your own reflections
- **🔒 Privacy-First**: All data stays on your device. No cloud sync, tracking, or external data collection
- **📱 Native iOS**: Built with SwiftUI and SwiftData for optimal performance on iPhone and iPad
- **🌐 Offline-First**: Core functionality works without internet connection (bundled fonts, no runtime fetches)
- **📅 Calendar View**: List ⇄ Calendar segmented toggle; month grids with treatment-colored day markers, newest month first
- **🎵 Music Links**: Playlist/track/album previews for oEmbed-capable providers (Spotify, YouTube, SoundCloud, Tidal), plus link-only fallbacks for Apple Music/Podcasts and Bandcamp
- **♿ Accessibility**: VoiceOver support and Dynamic Type compliance
- **📚 History Filters**: In-place search over intentions and reflections (with matching passages quoted in results), treatment filter chips, and sort options
- **⏰ Reflection Reminders**: Optional reminders that open straight into the reflection screen
- **📤 Data Export**: On-device CSV or PDF exports with date/treatment filters and progress feedback
- **🎨 Organic Design System**: Warm token-driven palette (terracotta/sage/cream), Caprasimo + Figtree type, full dark-mode support

### Therapeutic Value

Afterflow helps users:
- Track therapeutic progress over time
- Reflect on session experiences and insights
- Maintain detailed records for clinical discussions
- Understand patterns in mood and treatment response
- Export data for sharing with healthcare providers

## Screenshots

*Screenshots coming soon as UI development progresses*

## Requirements

- **iOS 17.6+** (iPhone and iPad)
- **Xcode 26.0+** for development
- **macOS 15.0+** for development environment

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

# SessionStore tests only
xcodebuild test -scheme Afterflow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AfterflowTests/SessionStoreTests
```

### Test Coverage

Current test coverage includes:
- **Model Tests**: TherapeuticSession entity validation, computed properties, data management
- **ViewModel Tests**: Form validation, mood rating scales, reminder options, session list filters/sorts
- **Service Tests**:
  - SessionStore: CRUD operations, auto-save, draft recovery, validation
  - MusicLinkMetadataService: Classification, oEmbed decoding, duration parsing, link-only fallbacks
  - CSVImportService: CSV parsing, data validation, music link restoration
  - CSVExportService: RFC-4180 compliant CSV generation, injection guards
  - PDFExportService: PDF generation, pagination, formatting
  - ReminderScheduler: Notification scheduling and cancellation
  - NotificationHandler: Deep link routing and session validation
- **ViewModel Tests** also cover TrendsViewModel aggregates (ranges, mood series, lift by treatment, word frequencies)
- **UI Tests**: Session form validation, keyboard navigation, mood scale (VoiceOver + Dynamic Type), reflections editing, delete, and a full-app screenshot tour
- **Performance Tests**: Large dataset filtering/fetching (1k+ sessions) and app launch instrumentation

**Coverage Target**: 80% minimum (currently achieved)

### Test Categories

- **Unit Tests** (`AfterflowTests/`): Model and service layer testing
- **UI Tests** (`AfterflowUITests/`): User interface workflow testing  
  - Use launch arguments `-ui-testing -ui-musiclink-fixtures` to seed sample sessions with Spotify and Apple Music links during UI runs
- **Performance Tests**: Data handling and app launch metrics

## Formatting & Linting

SwiftFormat and SwiftLint enforce consistent style across the app and test targets.

1. Install the tools if necessary: `brew install swiftformat swiftlint`
2. Run both before committing so CI stays clean:

```bash
./Scripts/run-swiftformat.sh
./Scripts/run-swiftlint.sh
```

Resolve all violations (or document intentional suppressions) so CI stays clean.

## Project Structure

```
Afterflow/
├── Models/
│   ├── TherapeuticSession.swift
│   └── TreatmentTypeAppearance.swift    # Treatment earth-tone colors and initials
├── Services/
│   ├── SessionStore.swift
│   ├── ReminderScheduler.swift
│   ├── NotificationHandler.swift
│   ├── MusicLinkMetadataService.swift
│   ├── CSVImportService.swift
│   ├── CSVExportService.swift
│   └── PDFExportService.swift
├── Support/
│   ├── CalendarGridHelper.swift         # Calendar month/grid generation logic
│   ├── CollapsibleCalendarSupport.swift # Calendar extension helpers
│   ├── MarkdownRenderer.swift
│   ├── RelativeDateHelper.swift
│   └── SeedDataFactory.swift
├── ViewModels/
│   ├── ExportState.swift                # Centralized export state management
│   ├── ImportState.swift                # Centralized import state management
│   ├── FormValidation.swift
│   ├── MoodRatingScale.swift
│   ├── ReminderOption.swift
│   ├── SessionListViewModel.swift       # Filter/sort/search with memoization
│   └── TrendsViewModel.swift            # On-device mood/trend aggregates
├── Views/
│   ├── ContentView.swift                # Main NavigationSplitView container
│   ├── ContentView/
│   │   ├── SessionListSection.swift     # List surface: header, search, nudge, rows
│   │   └── CalendarSection.swift        # Calendar surface (newest month first)
│   ├── SessionFormView.swift
│   ├── SessionDetailView.swift
│   ├── ReflectionEntryView.swift        # Dedicated reflection entry screen
│   ├── TrendsView.swift                 # Mood-over-time charts and stats
│   ├── Components/
│   │   ├── SearchPanel.swift            # In-place search, filter chips, sort
│   │   ├── SessionRowView.swift         # Session list row
│   │   ├── MoodBars.swift               # Tappable ten-step mood scale
│   │   ├── MoodRatingView.swift         # Titled wrapper around MoodBars
│   │   ├── MusicLinkSummaryCard.swift
│   │   ├── MusicLinkMetadataPreview.swift
│   │   ├── MusicLinkRawPreview.swift
│   │   ├── RichTextEditor.swift
│   │   └── ExportSheetView.swift
│   ├── Modifiers/
│   │   ├── NavigationAlertsModifier.swift
│   │   ├── ExportFlowsModifier.swift
│   │   ├── ImportFlowsModifier.swift
│   │   ├── SettingsAlertModifier.swift
│   │   └── ErrorAlertModifier.swift     # Reusable error alert modifier
│   └── Shared/
│       ├── AFSegmentedControl.swift     # Capsule segmented control
│       ├── ChipRow.swift                # FlowLayout + AFChip
│       ├── KickerLabel.swift            # Uppercase section labels
│       ├── StatusTag.swift              # Complete/Reflect/Draft tags
│       ├── TokenCard.swift              # Standard content card
│       └── TreatmentAvatar.swift        # Flat treatment-color avatar
├── Utilities/
│   ├── DesignConstants.swift            # Spacing, radii, shadows, animation values
│   ├── DesignTokens.swift               # AF color/typography tokens + button styles
│   └── FontRegistrar.swift              # Registers bundled fonts at launch
└── Resources/
    ├── Assets.xcassets/                 # Incl. Theme/ + Treatment/ color namespaces
    ├── Fonts/                           # Caprasimo + Figtree (bundled, offline)
    └── LaunchScreen.storyboard

AfterflowTests/
├── Helpers/
│   ├── SessionFixtureFactory.swift
│   ├── ErrorFixtureFactory.swift
│   └── TestHelpers.swift
├── ModelTests/
│   └── TherapeuticSessionTests.swift
├── ServiceTests/
│   ├── SessionStoreTests.swift
│   ├── ReminderSchedulerTests.swift
│   ├── NotificationHandlerTests.swift
│   ├── MusicLinkMetadataServiceTests.swift
│   ├── CSVImportServiceTests.swift
│   ├── CSVExportServiceTests.swift
│   └── PDFExportServiceTests.swift
├── SupportTests/
│   ├── CalendarGridHelperTests.swift    # Calendar logic unit tests
│   ├── CollapsibleCalendarSupportTests.swift
│   ├── MarkdownRendererTests.swift
│   └── RelativeDateHelperTests.swift
├── ViewModelTests/
│   ├── ExportStateTests.swift
│   ├── ImportStateTests.swift
│   ├── FormValidationTests.swift
│   ├── MoodRatingScaleTests.swift
│   ├── ReminderOptionTests.swift
│   ├── SessionListViewModelTests.swift
│   └── TrendsViewModelTests.swift
├── ComponentTests/
│   ├── SearchPanelTests.swift
│   ├── SessionRowViewTests.swift
│   ├── MoodRatingViewTests.swift
│   └── ExportSheetViewTests.swift
├── UtilityTests/
│   └── FontRegistrarTests.swift
├── ModifierTests/
│   └── ViewModifierTests.swift
├── IntegrationTests/
│   ├── ExportImportIntegrationTests.swift
│   └── ViewModelIntegrationTests.swift
├── Performance/
│   └── SessionListPerformanceTests.swift
```

## Architecture

Afterflow follows a clean architecture pattern optimized for SwiftUI with strong separation of concerns:

- **Models**: SwiftData entities for local persistence
- **Services**: Data access and business logic
- **ViewModels**: Observable state management with dedicated state objects
- **Views**: Modular SwiftUI components organized by feature
- **Utilities**: Shared constants and helper functions

### Key Principles

1. **Privacy-First**: No external data transmission
2. **SwiftUI + SwiftData Native**: Modern Apple frameworks
3. **Offline-First**: Local-first data storage
4. **Careful Network Use**: Only oEmbed fetches for supported music providers; no playback, tracking, or analytics
5. **Test-Driven**: 80% minimum test coverage
6. **Therapeutic Value**: Every feature supports healing
7. **Modular Design**: Single Responsibility Principle with focused, reusable components
8. **Performance**: Memoization and optimization for large datasets

## Music Link Support

- **Tier 1 (oEmbed metadata)**: Spotify, YouTube, SoundCloud, Tidal  
  - Fetches title/author/thumbnail/duration via oEmbed; displays duration (e.g., “1 hr 23 min”) when available.
- **Tier 2 (link-only providers)**: Apple Music, Apple Podcasts, Bandcamp, custom  
  - Parses titles from URLs when metadata isn’t available; uses brand logos and fallback thumbnails.
- **Branding**: Provider logos stored in `Assets.xcassets/Brands` with light/dark variants; UI falls back to a music note when unavailable.
- **Privacy**: No playback or authentication; only lightweight metadata fetches for oEmbed-capable providers.

## Export Usage
- Open the Sessions list, tap the **⋯ menu → Export**, choose CSV or PDF, and optionally filter by date range or treatment type.
- Exports run locally and present the iOS file exporter/share sheet; temporary files are cleaned after completion.
- CSVs use RFC‑4180 quoting and injection guards; PDFs include session summaries with optional cover pages.

## CSV Import Guide

Afterflow supports importing session data from CSV files, making it easy to:
- Migrate data from other apps or spreadsheets
- Bulk-add sessions from clinical records
- Restore previously exported data

### CSV Format Requirements

The CSV must be **UTF-8 encoded** with the following header row (exact column names required):

```
Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL
```

### Column Specifications

| Column | Format | Valid Values | Example |
|--------|--------|--------------|---------|
| **Date** | Medium date + short time (en_US_POSIX) | `MMM d, yyyy 'at' h:mm a` | `Dec 10, 2024 at 2:30 PM` |
| **Treatment Type** | Text | `Psilocybin`, `LSD`, `DMT`, `MDMA`, `Ketamine`, `Ayahuasca`, `Mescaline`, `Cannabis`, `Other` | `Psilocybin` |
| **Administration** | Text | `Intravenous (IV)`, `Intramuscular (IM)`, `Oral`, `Nasal`, `Other` | `Oral` |
| **Intention** | Text | Any non-empty string | `To explore creativity` |
| **Mood Before** | Integer | 1-10 | `5` |
| **Mood After** | Integer or empty | 1-10, or empty when not yet recorded | `8` |
| **Reflections** | Text | Any string (can be empty) | `Felt peaceful and connected` |
| **Music Link URL** | URL | Any valid URL or empty | `https://open.spotify.com/playlist/...` |

### Creating a CSV Template

#### Option 1: Use the Built-in Example
The quickest way to get a valid template:
1. Open Afterflow
2. Tap **Menu → Help → Example Import**
3. Save the example CSV file
4. Open it in your preferred editor and modify as needed

#### Option 2: Export Existing Data
If you already have sessions in Afterflow:
1. Create one or two sample sessions
2. Export them as CSV
3. Use the exported file as your template

#### Option 3: Create Manually
Create a text file with a `.csv` extension and use this template:

```csv
Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL
Dec 10, 2024 at 2:30 PM,Psilocybin,Oral,To explore creativity and connection,5,8,"Felt peaceful, connected to nature. Insights about relationships.",https://open.spotify.com/playlist/37i9dQZF1DX4dyzvuaRJ0n
Dec 3, 2024 at 10:00 AM,Ketamine,Intravenous (IV),Process grief and find acceptance,4,7,Gentle experience. Worked through difficult emotions.,
Nov 15, 2024 at 6:45 PM,MDMA,Oral,Healing trauma with therapist,3,9,"Breakthrough session. Finally felt safe enough to process childhood memories. So grateful.",https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

### Important Notes

1. **Date Format**: Must match exactly `MMM d, yyyy 'at' h:mm a` (e.g., `Dec 10, 2024 at 2:30 PM`)
2. **Quoted Fields**: Fields containing commas, quotes, or newlines must be wrapped in double quotes (`"`)
3. **Escaped Quotes**: Use `""` (two double quotes) to include a quote character within a quoted field
4. **Music Links**:
   - Can be any valid URL (Spotify, YouTube, Apple Music, etc.)
   - Leave empty if no music link
   - The app will automatically classify the provider and fetch metadata for supported services
5. **Excel/Google Sheets**: If creating in a spreadsheet app:
   - Format the Date column exactly as shown
   - Save/Export as CSV (UTF-8)
   - Verify the exported file matches the expected format

### CSV Injection Protection

Afterflow automatically protects against CSV injection attacks:
- Fields starting with `=`, `+`, `-`, or `@` are prefixed with `'` during export
- When importing, these prefixes are stripped automatically
- You don't need to manually handle this unless creating files outside of Afterflow exports

### Using the Import Feature

1. Prepare your CSV file following the format above
2. Transfer the file to your iOS device (via AirDrop, Files app, email, etc.)
3. Open Afterflow
4. Tap the **⋯ menu → Import**
5. Select your CSV file
6. Review the import summary
7. Confirm to add the sessions

### Troubleshooting

**"Invalid header" error:**
- Verify the header row exactly matches: `Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL`
- Check for extra spaces or typos in column names

**"Invalid row" error:**
- Check the date format matches exactly (Medium date + short time)
- Verify Treatment Type and Administration values match the valid options
- Ensure Mood Before is an integer between 1-10, and Mood After is 1-10 or empty
- Make sure all required fields (Date through Mood Before) have values

**"Data is not UTF-8 encoded" error:**
- Re-save your CSV file with UTF-8 encoding
- In Excel: Save As → CSV UTF-8
- In Google Sheets: Download → CSV automatically uses UTF-8

## Contributing

This is a personal therapeutic app project. While the code is public for transparency, direct contributions are not currently accepted. However, feedback and suggestions are welcome through Issues.

## Privacy & Data

### Data Collection: None
Afterflow collects **zero** personal data. All information stays on your device.

### Data Storage
- **Local Only**: SwiftData with SQLite backing
- **No Cloud Sync**: Data never leaves the device
- **No Analytics**: No usage tracking or crash reporting

### Data Export
- **User Controlled**: Export only when explicitly requested
- **Local Processing**: All export operations happen on-device
- **Secure Sharing**: Uses iOS standard sharing mechanisms

## Support

- **Issues**: Report bugs or request features via GitHub Issues

## License

CC0 1.0 Universal

---

**Afterflow** - Supporting healing through thoughtful session reflection.

*Built with privacy, therapeutic value, and iOS excellence in mind.*
