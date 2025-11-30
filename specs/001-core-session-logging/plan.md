# Implementation Plan — Core Session Logging (v2)

## Overview
Implements FR-001 → FR-010 using SwiftUI + SwiftData in modular structure.

## Technical Context
**Language/Version:** Swift 5.9+ / iOS ≥ 17.6 (tested on 17.6+)  
**Frameworks:** SwiftUI, SwiftData, Foundation, XCTest  
**Storage:** SwiftData (local SQLite)  
**Testing:** TDD (Red-Green-Refactor) + XCTest unit + XCUITest UI + Accessibility snapshots  
**Performance Goals:** Launch < 2s; I/O < 16ms main thread; Create + Save < 60s  
**Architecture:** MVVM with pure SwiftUI views and derived state ViewModels.  
**Privacy:** All data local; no analytics SDKs.  

## File Structure
```
Models/        TherapeuticSession.swift
ViewModels/    SessionListViewModel.swift, FormValidation.swift, MoodRatingScale.swift
Views/
 ├── SessionFormView.swift
 ├── SessionDetailView.swift
 ├── ContentView (history list + filters)
 └── Components/
     ├── MoodRatingView.swift
     ├── SessionStatusIndicatorView.swift
     ├── MusicLinkSummaryCard.swift
     └── UndoBannerView.swift
Services/      SessionStore.swift, ReminderScheduler.swift
Tests/
 ├── ModelTests/
 ├── ServiceTests/
 ├── UITests/
 └── Performance/
```

## Phases & Milestones
| Phase | Focus | Key Deliverables |
|-------|--------|------------------|
| 1 | Model & Persistence | SwiftData entity + auto-save service |
| 2 | Session Form | SwiftUI form + validation + draft recovery |
| 3 | Status & Reminder UX | field grouping, banner, reminder prompt |
| 4 | Mood Ratings | sliders + emoji + A11y tests |
| 5 | Reflections | editable detail + auto-save + error banner |
| 6 | History List | list view + delete + Undo + perf tests |
| 7 | Polish & QA | A11y, perf, migration note, privacy manifest |

## Success Metrics
- Time to first entry ≤ 60 s.  
- QA compliance verified by tests.  
- No external network calls.  
- App Privacy manifest = Data Not Collected.  
