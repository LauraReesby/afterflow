repo: LauraReesby/afterflow
branch: main

## Last sync
date: 2026-08-14T00:59:27Z

### Updated in this project
- Recreated the five current screens from the SwiftUI source (list, search panel, calendar, detail, new-session sheet).
- Added a redesign in the Organic design system: warm cream ground, terracotta accent, sage second voice.
- New screens beyond today's app: mood-lift strip on the list and a prompt-led reflection entry screen.
- Copied the real provider logos from `Assets.xcassets/Brands` (Spotify, Apple Music) instead of drawing marks.

## Screen map
| Project screen | Repo files |
| --- | --- |
| Afterflow Current.dc.html · 1a Sessions list | Views/ContentView.swift, Views/ContentView/SessionListSection.swift, Views/Components/SessionRowView.swift, Views/Shared/TreatmentAvatar.swift, Models/TreatmentTypeAppearance.swift, Support/RelativeDateHelper.swift, Support/SeedDataFactory.swift |
| Afterflow Current.dc.html · 1b Search + filter | Views/Components/SearchControlBar.swift, Views/Components/ExpandableSearchView.swift, ViewModels/SessionListViewModel.swift |
| Afterflow Current.dc.html · 1c Calendar | Views/ContentView/SessionListSection.swift (calendarScrollView/monthGrid/dayCell), Support/CalendarGridHelper.swift |
| Afterflow Current.dc.html · 1d Session detail | Views/SessionDetailView.swift, ViewModels/MoodRatingScale.swift, Views/Components/MusicLinkSummaryCard.swift, Resources/Assets.xcassets/Brands/spotify.imageset |
| Afterflow Current.dc.html · 1e New session sheet | Views/SessionFormView.swift, ViewModels/FormValidation.swift, ViewModels/ReminderOption.swift |
| Afterflow Redesign.dc.html (all screens) | same sources as above; Models/TherapeuticSession.swift for statuses, mood and music fields |
| Afterflow Redesign Screens.dc.html | board of the redesign prototype states |
