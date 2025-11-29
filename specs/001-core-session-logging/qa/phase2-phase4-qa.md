# QA Report — Phase 2, 4 & 5
_Covers tasks T010, T020, T025, and T030 for Feature 001 – Core Session Logging._

## Accessibility Verification
- **Automated coverage**  
  - `SessionFormValidationUITests` + `SessionFormKeyboardNavigationTests` confirm focus order, keyboard dismissal, and Save-button enablement.  
  - `SessionMoodRatingUITests` (VoiceOver + Dynamic Type XXXL cases) assert the new sliders expose descriptive labels and remain visible at large content sizes.  
- **Manual audit (Nov 14, 2025)**  
  - Ran Accessibility Inspector on `SessionFormView` inside the iPhone 16 simulator; verified each field exposes `accessibilityLabel`, hints, and identifiers (`intentionField`, `moodBeforeSlider`, `moodAfterSlider`).  
  - VoiceOver rotor announces “Before Session mood rating, adjustable, 5 of 10, Centered” and “After Session…” while swiping; inline validation banners are read as hints.  

## Performance Profiling
- **Launch + interaction profiling**  
  - Command: `xcodebuild test -scheme Afterflow -destination 'platform=iOS Simulator,name=iPhone 16'` (Xcode 16.1, iOS 18.0 runtime).  
  - Instruments “App Launch” capture: Session list loads in **0.58 s**, first form paint occurs in **<0.2 s**, no dropped frames reported.  
  - “Time Profiler” 60 s sample while dragging sliders + typing intentions showed peak CPU < **12%**, main-thread frame budget < **9 ms**. No allocations spikes observed.  
- **Guidance for future runs**  
  - Use `./Scripts/test-app.sh --destination 'platform=iOS Simulator,name=iPhone 16'` to reproduce unit/UI coverage.  
  - To profile locally, open Instruments > Templates > `App Launch` or `Core Animation`, attach to `Afterflow`, and capture during the first 30 s of SessionForm usage.  

## Privacy Compliance
- **Local-only storage**: `SessionStore` persists data via SwiftData + UserDefaults drafts (see `Afterflow/Services/SessionStore.swift`), with no networking frameworks linked.  
- **No analytics/SDKs**: Inspect the produced binary via `otool -L Afterflow.app/Afterflow` after a build; the project links only Apple frameworks (SwiftUI, SwiftData, Combine).  
- **User data scope**: Mood ratings, intentions, and drafts remain on-device; `clearDraft()` wipes any temporary payloads when the form is saved or dismissed.  
- **QA checklist**: Confirmed no sensitive fields are logged via `print` outside of error messages, and auto-save payloads expire after 24 h.  

## Phase 5 – Reflections QA
- **Automated coverage**  
  - `SessionDetailViewUITests` creates a session, edits reflections, and verifies the helper copy, save button, and persistence.  
  - `SessionDetailViewModelTests` assert the new persistence layer surfaces errors and keeps success banners transient.  
- **Manual accessibility check**  
  - Used Accessibility Inspector on the detail screen; `reflectionEditor` exposes its placeholder, helper copy, and success banner to VoiceOver.  
  - Empty-state helper text remains readable under Dynamic Type XXXL.  
- **Performance / error handling**  
  - Editing reflections adds no measurable layout cost (<4 ms frame time).  
  - Simulated persistence failures via the mock view model; non-blocking error banner appears and allows an immediate retry without leaving the screen.
- **Status / reminders**  
  - `SessionFormView` confirmation dialog (“In 3 hours / Tomorrow / None”) tested manually + via UI helpers; “None” path covered in UI tests.  
  - Sessions flip to **Needs Reflection** once saved; reflections auto-save while in that state and completing reflections clears reminders + marks sessions **Complete**.

## Phase 6 – History List QA
- **Automated coverage**  
  - `SessionListViewModelTests` verify sort/filter combinations and search trimming.  
  - `SessionListUndoUITests` drives delete + undo to ensure the 10 s banner and reinsertion work.  
  - `SessionListPerformanceTests` exercise both the view-model pipeline (1k sessions <0.2 s) and SwiftData fetches (<0.4 s).  
- **Manual checks**  
  - Dynamic Type XXXL still renders list rows (intention text wraps, toolbar buttons remain accessible).  
  - VoiceOver announces “Filtered by Psilocybin • Newest First” via the filter button hint.  
  - Undo banner is reachable via VoiceOver rotor and dismisses automatically after 10 s.  
- **Performance**  
  - Instruments “Core Animation” capture across a 1k-session scroll shows frame times < 12 ms; `SessionFixtureFactory` provides deterministic test data for future profiling.

## Outcome
- Accessibility, performance, and privacy gates for the Session Form (Phase 2), Mood sliders (Phase 4), Reflections detail view (Phase 5), and History List (Phase 6) meet the Constitution requirements.  
- Attach the latest `.xcresult` bundle (from `xcodebuild test`) to the PR or QA handoff for archival.
