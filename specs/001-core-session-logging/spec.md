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

---

## User Stories
### US1 – Create New Session
**As a user** I want to open the app and quickly log a new session with date/time, treatment type, and intentions.  
**Acceptance:**
1. Default date/time pre-filled.  
2. Required-field validation and inline guidance.  
3. Keyboard dismisses gracefully on swipe or tap.  
4. Draft auto-save & recovery on relaunch.

### US2 – Add Environment & Music
**As a user** I want to capture my environment and music notes to recall the setting.  
**Acceptance:**
1. Free-text environment + music notes (Spotify URI later).  
2. Tone-checked helper copy → reflective guidance.  
3. Long inputs remain responsive.  

### US3 – Rate Session Mood
**As a user** I want to rate mood before / after the session.  
**Acceptance:**
1. Intuitive slider 1–10 with emoji feedback.  
2. VoiceOver announces slider labels + values.  
3. Dynamic Type XL+ layout passes A11y snapshot tests.  

### US4 – Post-Session Reflections
**As a user** I want to add reflections and integration notes later.  
**Acceptance:**
1. Empty-state helper copy encourages reflective writing.  
2. Auto-save on pause; persistence error shows non-blocking banner + retry.  

### US5 – View & Manage History
**As a user** I want to browse all sessions chronologically and manage them.  
**Acceptance:**
1. List displays date, mood indicator, treatment type.  
2. Tap → detail view.  
3. Delete → confirmation + 10 s Undo snackbar.  
4. 1 000-session dataset loads fast; scroll < 200 ms first paint.  

---

## Functional Requirements
| ID | Requirement |
|----|--------------|
| FR-001 | Create / read / update / delete TherapySession entities offline. |
| FR-002 | Validate required fields with inline guidance. |
| FR-003 | Auto-save drafts + recover after crash/close. |
| FR-004 | Support environment + music notes text fields. |
| FR-005 | Mood rating sliders (before/after). |
| FR-006 | Reflection text area + auto-save. |
| FR-007 | Chronological session list + detail view. |
| FR-008 | Delete + Undo flow. |
| FR-009 | Accessibility (VoiceOver, Dynamic Type). |
| FR-010 | Local encryption per iOS security layer. |

---

## Technical Requirements
| ID | Description |
|----|--------------|
| TR-001 | SwiftUI 5.9 + SwiftData on iOS ≥ 17.6 (tested on 17.6+). |
| TR-002 | SwiftData entity `TherapySession` fields:<br> `id (UUID)`, `date (Date)`, `treatmentType (Enum)`, `dose (String?)`, `intention (String?)`, `environment (String?)`, `musicNotes (String?)`, `beforeMood (Int?)`, `afterMood (Int?)`, `reflection (String?)`, `createdAt (Date)`, `updatedAt (Date)` |
| TR-003 | Offline SQLite storage; optional CloudKit sync later. |
| TR-004 | SwiftData queries in ViewModels only for derived state. |
| TR-005 | Biometric unlock (optional). |
| TR-006 | Performance → launch < 2 s; I/O < 16 ms main thread (constitutional requirements). |

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

---

## Amendment Notes
Feature spec updates require Constitution review and governance approval.
