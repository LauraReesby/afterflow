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
- **📤 Data Export**: On-device CSV or PDF exports with date/treatment filters and progress feedback, plus a full JSON backup you can restore
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
- Open the Sessions list, tap the **⋯ menu → Export**, choose CSV, PDF or Backup, and optionally filter CSV and PDF exports by date range or treatment type. Backup always includes every session.
- Exports run locally and present the iOS file exporter/share sheet; temporary files are cleaned after completion.
- CSVs use RFC‑4180 quoting and injection guards; PDFs include session summaries with optional cover pages.
- Backup saves a lossless JSON file of every session (see Backup Files under Privacy & Data). The export sheet shows when you last made one.

## CSV Import Guide

Import sessions from an Afterflow export or your own spreadsheet. Only **Date** is required; every other column is optional.

### Columns

Columns can be in any order, header names ignore case, spaces, `_` and `-`, and unknown columns are ignored.

| Field | Accepted header names | Values |
|-------|----------------------|--------|
| **Date** (required) | `Date`, `Session Date`, `Date Time`, `DateTime`, `When` | See date formats below |
| **Treatment** | `Treatment Type`, `Treatment`, `Substance`, `Medicine` | Case-insensitive; also `Mushrooms`, `Shrooms` (Psilocybin), `Acid` (LSD), `Molly`, `Ecstasy` (MDMA), `Esketamine`, `Spravato` (Ketamine) |
| **Administration** | `Administration`, `Route`, `Method` | `Oral`, `Nasal`, `IV`, `IM` or the full names; `By mouth`, `Intranasal` |
| **Intention** | `Intention`, `Intent`, `Goal` | Any text |
| **Mood before** | `Mood Before`, `Before Mood`, `Pre Mood`, `Mood Pre` | 1-10, `7/10` or `6.5` (rounds up) |
| **Mood after** | `Mood After`, `After Mood`, `Post Mood`, `Mood Post` | Same; leave empty if not yet recorded |
| **Reflections** | `Reflections`, `Reflection`, `Notes`, `Journal` | Any text |
| **Music link** | `Music Link URL`, `Music Link`, `Music`, `Playlist` | A URL, or empty |

### What the importer accepts

- **Separators and encodings**: comma, semicolon or tab separated; UTF-8 (with or without a BOM) and the Windows-1252 and Mac Roman text that older Excel versions save. UTF-16 files are not supported, so choose **CSV UTF-8** when saving.
- **Dates**: the format Afterflow exports, ISO 8601 (`2024-12-10T14:30:00Z`), `2024-12-10 14:30` and `2024-12-10`, slash dates such as `12/10/2024`, and month names such as `10 Dec 2024` or `December 10, 2024`. The time is optional and may be 12 or 24 hour. Slash dates read day first or month first according to your device region, and times without a time zone are taken as local time.
- **Treatment and administration**: matching is case-insensitive. A value Afterflow does not recognise is saved as **Other** and the original text is added to the session's reflections.
- **Moods**: a missing mood before becomes 5. A mood that is not a number from 1 to 10 makes that row unreadable.
- **Unreadable rows**: a row with an unrecognised date or an invalid mood is skipped, not fatal. The confirmation lists the row numbers (header row is 1), never the contents. If no row can be read, nothing is imported.
- **Duplicates**: re-importing is safe. Sessions already in Afterflow, with the same minute, treatment and intention, are skipped.
- **Formula guard**: Afterflow's CSV export prefixes `'` to text starting with `=`, `+`, `-` or `@`. Import removes that prefix again, but only in that case, so other apostrophes are kept.

### Creating a template

The quickest way is **Menu → Help → Example Import**, which saves a sample file you can edit. You can also export a few sessions as CSV and use that, or start from this:

```csv
Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL
2024-12-10 14:30,Psilocybin,Oral,To explore creativity,5,8,"Felt peaceful, connected to nature.",https://open.spotify.com/playlist/37i9dQZF1DX4dyzvuaRJ0n
2024-12-03 10:00,Ketamine,IV,Process grief,4,7,Gentle experience.,
```

Wrap cells containing commas, quotes or line breaks in double quotes, and double any quote inside them (`""`).

### Using the import feature

1. Transfer the file to your device (AirDrop, Files, email).
2. Tap the **⋯ menu → Import** and pick the file.
3. Review the confirmation, which reports skipped rows, defaulted moods and unrecognised treatments, then confirm.
4. A summary shows how many sessions were added and how many were already in Afterflow.

The same **Import** item restores Afterflow backup files (`.json`): sessions already on the device are kept, and matching ones are updated only if the backup is newer.

### Troubleshooting

- **"Missing the required Date column"**: add a header row with a `Date` column (or one of its alternative names).
- **"None of the rows could be imported"**: check dates are in a supported format and moods are 1-10.
- **"No sessions were found in this file"**: the file has a header row but no data rows.
- **Garbled characters**: re-save as CSV UTF-8 (Excel: Save As → CSV UTF-8; Google Sheets: Download → CSV).

## Contributing

This is a personal therapeutic app project. While the code is public for transparency, direct contributions are not currently accepted. However, feedback and suggestions are welcome through Issues.

## Privacy & Data

### Data Collection: None
Afterflow collects **zero** personal data. All information stays on your device.

### Data Storage
- **Local Only**: SwiftData with SQLite backing
- **No Cloud Sync**: Afterflow never sends your data anywhere. Like any app's data, it is included in your own iOS device backups (iCloud Backup or Finder), which Apple encrypts
- **Backup Files**: Choose **⋯ menu → Export → Backup** to save a complete backup file at any time, and restore it later with **⋯ menu → Import**, even on a new device. Restoring never duplicates or deletes sessions. The file isn't encrypted, so keep it somewhere private
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
