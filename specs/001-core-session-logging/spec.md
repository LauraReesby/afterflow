# Feature Spec — Core Session Logging (v2)
**Feature ID:** 001  
**Status:** Active  
**Constitution Reference:** v1.0.0  
**Owner:** Product + Engineering  

## Intent
Enable users to privately log therapeutic sessions capturing *set (mindset)* and *setting (environment, music)* while fully offline.  
Goal: fast, calming journaling flow in < 60 s with full user data control.

## Problem
Users of psychedelic-assisted therapy lack a safe, private way to record intentions, environment, and reflections.  
Existing solutions require network access or expose data.

## Success Criteria
- Create and save a session in < 60 s from launch.  
- 100 % offline functionality.  
- All fields editable and persisted locally.  
- UI tone: reflective / neutral / non-clinical.  
- QA compliance met per Constitution § Quality Gates.  
- Session status clearly reflects progress (Draft ➜ Needs Reflection ➜ Complete) with reminder support.

---

## Session Status States
- **🟦 Draft:** The user is filling out the core form. Drafts are held in-memory only (auto-save/draft-recovery) and not written to SwiftData. A session becomes a “draft” when:
  - `sessionDate` (defaults to now) is set  
  - `treatmentType` (defaults to psilocybin) is chosen  
  - `moodBefore` slider has a value  
  - `intention` is non-empty  
- **🟧 Needs Reflection:** Once the user saves the draft (above fields complete), the session is persisted. The app prompts: “Would you like a reminder to add reflections later?” with options **In 3 hours / Tomorrow / None**. Selecting a reminder schedules a local notification. Sessions in this state are highlighted in the list until reflections are added.  
- **🟩 Complete:** Reflections (and any remaining optional fields) have been captured; the reminder (if any) is cleared.

## User Stories
### US1 – Create New Session
**As a user** I want to open the app and quickly log a new session with date/time, treatment type, moods, and intentions.  
**Acceptance:**
1. Default date/time pre-filled.  
2. Required-field validation and inline guidance.  
3. Keyboard dismisses gracefully on swipe or tap.  
4. Draft auto-save & recovery on relaunch.  
5. Draft is only persisted once the “Needs Reflection” state begins (after mood + intention complete).  
6. After saving the draft, prompt for reminder: “Would you like a reminder to add reflections later?” with the four options above.

### US2 – Add Environment & Music
**As a user** I want to capture my environment and music notes to recall the setting.  
**Acceptance:**
1. Free-text environment + music notes (Spotify URI later).  
2. Tone-checked helper copy → reflective guidance.  
3. Long inputs remain responsive.  
4. Fields visually grouped as “Later” so users understand they unlock after the draft phase.  

### US3 – Rate Session Mood
**As a user** I want to rate mood before / after the session.  
**Acceptance:**
1. Intuitive slider 1–10 with emoji feedback.  
2. VoiceOver announces slider labels + values.  
3. Dynamic Type XL+ layout passes A11y snapshot tests.  
4. Before-mood completion is required to transition from Draft to Needs Reflection.  

### US4 – Post-Session Reflections
**As a user** I want to add reflections and integration notes later.  
**Acceptance:**
1. Empty-state helper copy encourages reflective writing.  
2. Once a session is in “Needs Reflection,” any changes (reflections, environment, music, moodAfter) auto-save to SwiftData; persistence errors surface non-blocking banner + retry.  
3. Reminder selections fire local notifications until dismissed by saving reflections.  
4. Sessions in “Needs Reflection” state display a banner in lists/detail and can be tapped to resume; once reflections saved, reminder clears and status flips to Complete.

### US5 – View & Manage History
**As a user** I want to browse all sessions chronologically and manage them.  
**Acceptance:**
1. List displays date, mood indicator, treatment type, **and status badge (Needs Reflection)**.  
2. Tap → detail view.  
3. Delete → confirmation + 10 s Undo snackbar.  
4. 1 000-session dataset loads fast; scroll < 200 ms first paint.  
5. Needs Reflection rows visually distinct (icon/badge) until reflections entered.

---

### Session Status Lifecycle
- **🟦 Draft** (not persisted): sessionDate + treatmentType defaulted, user supplies intention + before mood while everything lives in view-model memory.  
- **🟧 Needs Reflection**: once intention + before mood saved, persist session, prompt for reflection reminder schedule, unlock after-mood + reflection inputs.  
- **🟩 Complete**: reflections saved (or dismissed) and reminder cleared. List/detail badges show latest state, and reminders can be canceled anytime in Needs Reflection.

---

## Functional Requirements
| ID | Requirement |
|----|--------------|
| FR-001 | Create / read / update / delete TherapeuticSession entities offline. |
| FR-002 | Validate required fields with inline guidance. |
| FR-003 | Auto-save drafts + recover after crash/close. |
| FR-003a | Drafts remain in volatile storage until the “Needs Reflection” threshold is passed; persisted sessions track status. |
| FR-004 | Support environment + music notes text fields. |
| FR-005 | Mood rating sliders (before/after). |
| FR-006 | Reflection text area + auto-save (live once “Needs Reflection”), with reminder scheduling. |
| FR-007 | Chronological session list + detail view (status-aware). |
| FR-008 | Delete + Undo flow + reminder cancellation when undoing. |
| FR-009 | Accessibility (VoiceOver, Dynamic Type). |
| FR-010 | Local encryption per iOS security layer. |
| FR-011 | Prompt for reminder options (“In 3 hours”, “Tomorrow”, “None”), schedule/cancel per selection, and surface status in list/detail. |
| FR-012 | Visually separate “Complete the draft” fields from “Reflections later” fields in the SessionFormView. |

---

## Technical Requirements
| ID | Description |
|----|--------------|
| TR-001 | SwiftUI 5.9 + SwiftData on iOS ≥ 17.6 (tested on 17.6+). |
| TR-002 | SwiftData entity `TherapeuticSession` fields:<br> `id (UUID)`, `date (Date)`, `treatmentType (Enum)`, `dose (String?)`, `intention (String?)`, `environment (String?)`, `musicNotes (String?)`, `beforeMood (Int?)`, `afterMood (Int?)`, `reflection (String?)`, `createdAt (Date)`, `updatedAt (Date)` |
| TR-003 | Offline SQLite storage; optional CloudKit sync later. |
| TR-004 | SwiftData queries in ViewModels only for derived state. |
| TR-005 | Biometric unlock (optional). |
| TR-006 | Performance → launch < 2 s; I/O < 16 ms main thread (constitutional requirements). |
| TR-007 | Session state machine owned by ViewModel; SwiftData stores `status` enum once persisted plus reminder metadata. |
| TR-008 | Reminder scheduling implemented via `UNUserNotificationCenter` with notification categories allowing quick mark-as-complete. |

---

## QA Standards
**Constitutional Quality Gates (non-negotiable):**
- **Test Coverage**: Minimum 80% code coverage before any feature merge.
- **Public API Coverage**: 100% test coverage required for all public functions and methods.
- **Test-Driven Development (TDD)**: Red-Green-Refactor sequence mandatory for all public interfaces.
- **Accessibility**: VoiceOver compliance, Dynamic Type support testing.
- **Performance**: Memory usage profiling, battery impact assessment.
- **Privacy**: Local data encryption verification, no external data leakage testing.
- **UX Standards**: Calming, non-judgmental interface; reflective and neutral communication tone.
- **Test Types**: Unit tests (models, ViewModels, services), UI tests (user workflows), Integration tests (data persistence).  
- **Reminder Accuracy**: Automated tests verifying reminders fire/cancel based on status transitions.

---

## Dependencies
None (except system frameworks).  

---

## Risks & Mitigation
| Risk | Mitigation |
|------|-------------|
| Data loss on app close | Auto-save drafts + restore tests. |
| Accessibility failures | Snapshot + VoiceOver automation tests. |
| User overwhelm | Limit fields; calming UI review per release. |
| Reminder fatigue | Provide “None” default + cancel controls from detail view and notifications. |

---

## Amendment Notes
Feature spec updates require Constitution review and governance approval.
