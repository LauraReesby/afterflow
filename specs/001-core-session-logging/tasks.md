# Tasks: Core Session Logging

**Input**: Design documents from `/specs/001-core-session-logging/`
**Prerequisites**: plan.md (required), spec.md (required for user stories)

**Testing**: Tests are MANDATORY for all features with 80% minimum coverage requirement. 100% test coverage required for all public functions and methods.

**Task Completion Protocol**: Tasks can only be marked as complete (✅) after:
1. Implementation is finished
2. All tests pass (including new tests for any public functions)
3. Code coverage meets 80% minimum requirement (100% for public APIs)
4. Feature functionality is verified
5. NEVER implement public functions without corresponding tests

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Update project structure per implementation plan in SetAndSetting/
- [ ] T002 Configure SwiftData model container in SetAndSettingApp.swift
- [ ] T003 [P] Create folder structure: Models/, Views/, ViewModels/, Services/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 Create base SwiftData models with proper relationships
- [ ] T005 [P] Setup SessionDataService for data access abstraction
- [ ] T006 [P] Create TreatmentType enumeration in Models/TreatmentType.swift
- [ ] T007 [P] Create MoodRating model in Models/MoodRating.swift
- [ ] T008 Setup navigation structure in main ContentView.swift
- [ ] T009 Configure SwiftData preview helpers for development
- [ ] T010 [P] Setup XCTest framework and code coverage reporting
- [ ] T011 [P] Create test utilities and mock data helpers in TestSupport/

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Create New Session Entry (Priority: P1) 🎯 MVP

**Goal**: Users can create and save basic session entries with core therapeutic data

**Independent Test**: User can open app, tap "New Session", fill basic fields (date, treatment type, intentions), and save successfully

### Tests for User Story 1 (MANDATORY - 80% Coverage + 100% Public API Coverage Required) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**
> **CRITICAL: NEVER implement public functions without corresponding tests**

- [ ] T012 [P] [US1] Unit tests for TherapySession model in SetAndSettingTests/ModelTests/TherapySessionTests.swift
- [ ] T013 [P] [US1] Unit tests for TreatmentType model in SetAndSettingTests/ModelTests/TreatmentTypeTests.swift
- [ ] T014 [P] [US1] Unit tests for SessionFormViewModel in SetAndSettingTests/ViewModelTests/SessionFormViewModelTests.swift
- [ ] T015 [P] [US1] Unit tests for SessionDataService in SetAndSettingTests/ServiceTests/SessionDataServiceTests.swift
- [ ] T016 [P] [US1] Unit tests for ALL public functions with 100% coverage requirement
- [ ] T017 [P] [US1] UI tests for session creation workflow in SetAndSettingUITests/SessionCreationUITests.swift
- [ ] T018 [P] [US1] Integration tests for session persistence in SetAndSettingTests/IntegrationTests/SessionPersistenceTests.swift

### Implementation for User Story 1

> **CRITICAL: All public functions MUST have corresponding tests before implementation**

- [ ] T019 [P] [US1] Create TherapySession model in Models/TherapySession.swift with core properties
- [ ] T020 [P] [US1] Create TreatmentTypePicker component in Views/Components/TreatmentTypePicker.swift
- [ ] T021 [US1] Create SessionFormView in Views/SessionFormView.swift for session creation
- [ ] T022 [US1] Create SessionFormViewModel in ViewModels/SessionFormViewModel.swift for form state management
- [ ] T023 [US1] Update main ContentView.swift to show "Add Session" button and navigation
- [ ] T024 [US1] Implement save functionality in SessionDataService with SwiftData persistence
- [ ] T025 [US1] Add form validation and error handling in SessionFormViewModel
- [ ] T026 [P] [US1] Create SwiftUI previews for SessionFormView with sample data
- [ ] T027 [US1] Verify 80% code coverage achieved for User Story 1 components (100% for public APIs)
- [ ] T028 [US1] Mark User Story 1 tasks complete only after full testing and coverage verification

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Add Environment and Music Details (Priority: P1)

**Goal**: Users can capture environment and music context for their sessions

**Independent Test**: User can add environment notes (location, lighting, comfort) and music information (playlist name, songs) to any session entry

### Tests for User Story 2 (MANDATORY - 80% Coverage Required) ⚠️

- [ ] T027 [P] [US2] Unit tests for environment/music properties in TherapySession model
- [ ] T028 [P] [US2] Unit tests for EnvironmentInputView component logic
- [ ] T029 [P] [US2] Updated unit tests for SessionFormViewModel with environment/music state
- [ ] T030 [P] [US2] UI tests for environment and music input workflows

### Implementation for User Story 2

- [ ] T031 [P] [US2] Add environment and music properties to TherapySession model
- [ ] T032 [P] [US2] Create EnvironmentInputView component in Views/Components/EnvironmentInputView.swift
- [ ] T033 [US2] Update SessionFormView to include environment and music sections
- [ ] T034 [US2] Update SessionFormViewModel to handle environment and music state
- [ ] T035 [US2] Add music input text field with placeholder guidance
- [ ] T036 [P] [US2] Update SwiftUI previews to include environment and music data
- [ ] T037 [US2] Verify 80% code coverage maintained for User Story 2 components
- [ ] T038 [US2] Mark User Story 2 tasks complete only after full testing and coverage verification

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Rate Session Experience (Priority: P2)

**Goal**: Users can capture quantitative mood ratings before and after sessions

**Independent Test**: User can set before/after mood ratings using intuitive slider interface and view these ratings in session history

### Tests for User Story 3 (MANDATORY - 80% Coverage Required) ⚠️

- [ ] T038 [P] [US3] Unit tests for MoodRating model and emoji mapping logic
- [ ] T039 [P] [US3] Unit tests for MoodRatingView component with various rating values
- [ ] T040 [P] [US3] Unit tests for mood rating state management in SessionFormViewModel
- [ ] T041 [P] [US3] UI tests for mood rating slider interaction and validation

### Implementation for User Story 3

- [ ] T042 [P] [US3] Add beforeMood and afterMood properties to TherapySession model
- [ ] T043 [US3] Create MoodRatingView component in Views/Components/MoodRatingView.swift with slider
- [ ] T044 [US3] Update SessionFormView to include before/after mood rating sections
- [ ] T045 [US3] Update SessionFormViewModel to handle mood rating state
- [ ] T046 [US3] Add mood emoji display based on numeric rating (1-10 to emoji mapping)
- [ ] T047 [P] [US3] Create mood rating SwiftUI previews with different rating values
- [ ] T048 [US3] Verify 80% code coverage maintained for User Story 3 components
- [ ] T049 [US3] Mark User Story 3 tasks complete only after full testing and coverage verification

**Checkpoint**: User Stories 1, 2, AND 3 should all work independently

---

## Phase 6: User Story 4 - Add Post-Session Reflections (Priority: P2)

**Goal**: Users can add and edit reflection notes on existing sessions

**Independent Test**: User can open any existing session, add or edit reflection notes, and save changes that persist

### Tests for User Story 4 (MANDATORY - 80% Coverage Required) ⚠️

- [ ] T049 [P] [US4] Unit tests for reflections property and editing logic in TherapySession model
- [ ] T050 [P] [US4] Unit tests for SessionDetailView editing functionality
- [ ] T051 [P] [US4] Unit tests for auto-save and reflection persistence
- [ ] T052 [P] [US4] UI tests for session editing and reflection workflows

### Implementation for User Story 4

- [ ] T053 [P] [US4] Add reflections property to TherapySession model
- [ ] T054 [US4] Create SessionDetailView in Views/SessionDetailView.swift for viewing/editing sessions
- [ ] T055 [US4] Update SessionFormView to include reflections text field
- [ ] T056 [US4] Implement edit mode functionality in SessionDetailView
- [ ] T057 [US4] Add auto-save or explicit save for reflection edits
- [ ] T058 [P] [US4] Create SwiftUI previews for SessionDetailView with sample reflections
- [ ] T059 [US4] Verify 80% code coverage maintained for User Story 4 components
- [ ] T060 [US4] Mark User Story 4 tasks complete only after full testing and coverage verification

**Checkpoint**: User Stories 1-4 should all be independently functional

---

## Phase 7: User Story 5 - View Session History (Priority: P1)

**Goal**: Users can see chronological list of sessions and navigate to details

**Independent Test**: User can see list of all logged sessions with date, mood indicator, and treatment type, and tap any session to view full details

### Tests for User Story 5 (MANDATORY - 80% Coverage Required) ⚠️

- [ ] T060 [P] [US5] Unit tests for SessionListViewModel and session filtering logic
- [ ] T061 [P] [US5] Unit tests for session list data queries and sorting
- [ ] T062 [P] [US5] UI tests for session list navigation and interaction workflows
- [ ] T063 [P] [US5] UI tests for empty state and large dataset scenarios

### Implementation for User Story 5

- [ ] T064 [US5] Create SessionListView in Views/SessionListView.swift with SwiftData Query
- [ ] T065 [US5] Create SessionListViewModel in ViewModels/SessionListViewModel.swift for list management
- [ ] T066 [US5] Update main ContentView.swift to use SessionListView as primary interface
- [ ] T067 [US5] Implement session list row design with date, mood indicator, treatment type
- [ ] T068 [US5] Add navigation from session list to SessionDetailView
- [ ] T069 [US5] Implement empty state view for when no sessions exist
- [ ] T070 [P] [US5] Add pull-to-refresh and basic list animations
- [ ] T071 [P] [US5] Create SwiftUI previews for SessionListView with various data states
- [ ] T072 [US5] Verify 80% code coverage maintained for User Story 5 components
- [ ] T073 [US5] Mark User Story 5 tasks complete only after full testing and coverage verification

**Checkpoint**: All core user stories should now be independently functional

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T073 [P] [Polish] Add accessibility labels and VoiceOver support across all views
- [ ] T074 [P] [Polish] Implement proper error handling and user feedback throughout app
- [ ] T075 [Polish] Add app icon and launch screen in Assets.xcassets
- [ ] T076 [P] [Polish] Performance optimization for large session lists (lazy loading)
- [ ] T077 [P] [Polish] Add haptic feedback for key interactions
- [ ] T078 [Polish] Implement data migration strategy for future model changes
- [ ] T079 [P] [Polish] Add accessibility UI tests in SetAndSettingUITests/AccessibilityUITests.swift
- [ ] T080 [P] [Polish] Add performance tests in SetAndSettingTests/PerformanceTests/
- [ ] T081 [Polish] Final code coverage validation - ensure 80% minimum across all components
- [ ] T082 [Polish] Code coverage reporting and documentation
- [ ] T083 [Polish] Mark all Polish tasks complete only after final testing and coverage verification

**Coverage Gate**: Verify final 80% code coverage requirement met before release

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - User stories can then proceed in priority order (P1 stories first)
  - US1 and US2 are both P1 and can be done in parallel after foundation
  - US3 and US4 are P2 and can start after P1 stories
  - US5 is P1 but depends on having sessions to display, so should come after US1-US2

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational - Builds on US1 session model but independently testable
- **User Story 3 (P2)**: Can start after Foundational - Builds on US1 session model
- **User Story 4 (P2)**: Can start after Foundational - Builds on US1 session model
- **User Story 5 (P1)**: Should start after US1/US2 complete to have data to display

### Recommended Implementation Order

1. **Phase 1 + 2**: Setup and Foundation (T001-T009)
2. **User Story 1**: Core session creation (T010-T017)
3. **User Story 2**: Environment and music (T018-T023) - parallel with US1 if desired
4. **User Story 5**: Session history view (T036-T043) - needs US1 data model
5. **User Story 3**: Mood ratings (T024-T029) - enhances existing sessions
6. **User Story 4**: Reflections editing (T030-T035) - enhances existing sessions
7. **Phase 8**: Polish and testing (T044-T051)

### Parallel Opportunities

- T003, T005, T006, T007 can run in parallel during Foundation phase
- T010, T011 can run in parallel during US1
- T018, T019, T023 can run in parallel during US2
- All SwiftUI preview tasks marked [P] can be done in parallel
- Polish tasks T044, T045, T047, T048, T050, T051 can run in parallel

---

## Implementation Strategy

### MVP First (User Stories 1, 2, 5 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL)
3. Complete User Story 1: Core session creation
4. Complete User Story 2: Environment and music details
5. Complete User Story 5: Session history view
6. **STOP and VALIDATE**: Test complete session creation and viewing workflow
7. Deploy/demo if ready - this provides a complete basic session logging app

### Full Feature Set

Continue with User Stories 3 and 4 to add mood ratings and reflection editing, then complete Polish phase for production readiness.

---

## Notes

- SwiftData models should be designed with future CloudKit sync in mind
- All views should support both iPhone and iPad with adaptive layouts
- Consider using @Observable for ViewModels in iOS 17+
- Implement proper SwiftUI state management to avoid data inconsistencies
- Test with VoiceOver and Dynamic Type for accessibility
- Use SwiftUI previews extensively for rapid iteration
- **CRITICAL**: Maintain 80% code coverage throughout development - check coverage after each task completion
- Write tests FIRST for each user story before implementation (TDD approach)
- All tests must pass before moving to next phase
- Code coverage reports should be generated and reviewed regularly
- **Task Completion Protocol**: Mark tasks complete (✅) ONLY after: Code Complete → Tests Pass → Coverage ≥80% → Functionality Verified