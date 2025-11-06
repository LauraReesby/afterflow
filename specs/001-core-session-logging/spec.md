# Feature Specification: Core Session Logging

**Feature Branch**: `001-core-session-logging`  
**Created**: 2025-11-05  
**Status**: Draft  
**Input**: User description: "A private, simple app for logging and reflecting on ketamine or psychedelic-assisted therapy sessions. Each entry captures the session's set (mindset), setting (environment), and music — the main factors that influence therapeutic outcomes."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create New Session Entry (Priority: P1)

A user wants to log a new therapy session immediately after or during their session to capture their state of mind, environment, and experience while it's fresh.

**Why this priority**: This is the core value proposition - without session logging, the app has no purpose. Must be simple enough to use while in altered states.

**Independent Test**: User can open app, tap "New Session", fill basic fields (date, treatment type, intentions), and save successfully. Data persists and appears in session list.

**Acceptance Scenarios**:

1. **Given** app is open, **When** user taps "Add Session" button, **Then** new session form appears with current date/time pre-filled
2. **Given** new session form is open, **When** user selects treatment type from picker (IV, IM, oral, lozenge, at-home, clinic), **Then** selection is saved to form
3. **Given** user enters dose amount (optional), **When** they save the session, **Then** dose is stored with the session
4. **Given** user enters intentions in text field, **When** they save session, **Then** intentions are stored and retrievable
5. **Given** form is completed with minimum required fields, **When** user taps "Save", **Then** session is saved and user returns to session list

---

### User Story 2 - Add Environment and Music Details (Priority: P1)

During or after a session, a user wants to capture details about their physical environment and music that contributed to their experience.

**Why this priority**: Set and setting are core therapeutic factors - environment and music directly impact outcomes and should be captured for pattern recognition.

**Independent Test**: User can add environment notes (location, lighting, comfort) and music information (playlist name, songs) to any session entry and retrieve this information later.

**Acceptance Scenarios**:

1. **Given** session form is open, **When** user taps "Environment" section, **Then** text field appears for location/comfort notes
2. **Given** environment section is open, **When** user enters lighting conditions and comfort level, **Then** details are saved with session
3. **Given** session form is open, **When** user taps "Music" section, **Then** text field appears for playlist/song information
4. **Given** music section is open, **When** user enters playlist name or specific songs, **Then** music details are saved with session

---

### User Story 3 - Rate Session Experience (Priority: P2)

After a session, a user wants to capture their mood/state before and after the session to track therapeutic progress over time.

**Why this priority**: Quantitative tracking enables pattern recognition and progress measurement, key for therapeutic value.

**Independent Test**: User can set before/after mood ratings using intuitive slider or emoji interface and view these ratings in session history.

**Acceptance Scenarios**:

1. **Given** session form is open, **When** user sees "Before Session" rating, **Then** they can select rating from 1-10 scale or emoji mood
2. **Given** session form is open, **When** user sees "After Session" rating, **Then** they can select rating from 1-10 scale or emoji mood
3. **Given** ratings are set, **When** user saves session, **Then** both ratings are stored and visible in session history

---

### User Story 4 - Add Post-Session Reflections (Priority: P2)

Hours or days after a session, a user wants to add reflections, insights, or integration notes to capture learnings and therapeutic value.

**Why this priority**: Reflection and integration are crucial for therapeutic benefit - delayed insights are common and valuable.

**Independent Test**: User can open any existing session, add or edit reflection notes, and save changes that persist.

**Acceptance Scenarios**:

1. **Given** session exists in history, **When** user taps on session entry, **Then** session detail view opens with reflection text field
2. **Given** session detail view is open, **When** user adds or edits reflection text, **Then** changes are saved automatically or on explicit save
3. **Given** user navigates away from session, **When** they return to same session, **Then** reflection text is preserved

---

### User Story 5 - View Session History (Priority: P1)

A user wants to see a chronological list of their past sessions with key details to track patterns and progress over time.

**Why this priority**: Historical view enables pattern recognition and therapeutic insights - core value of the logging concept.

**Independent Test**: User can see list of all logged sessions with date, mood indicator, and treatment type, and tap any session to view full details.

**Acceptance Scenarios**:

1. **Given** multiple sessions exist, **When** user opens app, **Then** main screen shows chronological list of sessions
2. **Given** session list is displayed, **When** user views session entry, **Then** date, treatment type, and mood indicator are visible
3. **Given** session appears in list, **When** user taps session entry, **Then** full session details view opens
4. **Given** no sessions exist, **When** user opens app, **Then** empty state with "Add First Session" prompt appears

---

### Edge Cases

- What happens when user starts session entry but doesn't complete it? (Auto-save draft or discard)
- How does system handle very long reflection text? (Text field should expand, consider character limits)
- What if user tries to enter session for future date? (Allow but show warning)
- How does system behave if user force-closes app during session entry? (Auto-save progress)
- What happens when date/time fields are left empty? (Use current date/time as default)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to create new therapy session entries with date/time
- **FR-002**: System MUST provide selection options for treatment types (IV, IM, oral, lozenge, at-home, clinic)
- **FR-003**: Users MUST be able to enter optional dose information as free text
- **FR-004**: System MUST provide text field for session intentions/goals
- **FR-005**: System MUST allow users to enter environment notes (location, lighting, comfort)
- **FR-006**: System MUST provide text field for music information (playlist names, songs)
- **FR-007**: System MUST allow users to rate their mood before session (1-10 scale or emoji)
- **FR-008**: System MUST allow users to rate their mood after session (1-10 scale or emoji)
- **FR-009**: System MUST provide text field for post-session reflections and insights
- **FR-010**: System MUST display chronological list of all logged sessions
- **FR-011**: System MUST allow users to view complete details of any past session
- **FR-012**: System MUST allow users to edit existing session entries and reflections
- **FR-013**: System MUST persist all session data locally using SwiftData
- **FR-014**: System MUST work entirely offline without internet connection
- **FR-015**: System MUST auto-save session progress to prevent data loss

### Testing Requirements (MANDATORY - NON-NEGOTIABLE)

**Test-Driven Development (TDD) Protocol - Constitutional Requirement**:
- **TR-001**: MUST follow Red-Green-Refactor sequence for all implementations
- **TR-002**: MUST write tests before implementation; ensure minimum 80% coverage
- **TR-003**: MUST achieve 100% test coverage for all public functions and methods  
- **TR-004**: NEVER implement public functions without corresponding tests (Test-First enforcement)
- **TR-005**: MUST verify all tests pass before marking any task complete

**Unit Testing Requirements**:
- **TR-006**: MUST include unit tests for all SwiftData models (TherapySession, TreatmentType, MoodRating) with comprehensive edge cases
- **TR-007**: MUST include unit tests for all ViewModels and business logic components
- **TR-008**: MUST include unit tests for SessionDataService and data persistence layer
- **TR-009**: MUST include unit tests for all public APIs with 100% coverage requirement

**UI Testing Requirements**:
- **TR-010**: MUST include UI tests for complete session creation workflow and acceptance scenarios
- **TR-011**: MUST include UI tests for session viewing and editing workflows
- **TR-012**: MUST include UI tests for session list navigation and interaction
- **TR-013**: MUST include UI tests for error states and edge cases

**Integration & Performance Testing**:
- **TR-014**: MUST include integration tests for SwiftData persistence and retrieval
- **TR-015**: MUST include performance tests for app launch (<2s requirement) and large dataset handling
- **TR-016**: MUST include performance tests for main-thread I/O operations (<16ms requirement)
- **TR-017**: MUST include memory usage profiling and battery impact assessment

**Accessibility & Quality Testing**:
- **TR-018**: MUST include accessibility tests for VoiceOver and Dynamic Type compliance
- **TR-019**: MUST include tests for data validation and error handling scenarios
- **TR-020**: MUST include tests for auto-save functionality and data recovery
- **TR-021**: MUST include tests for therapeutic context and user safety scenarios
- **TR-022**: MUST include tests for local data encryption verification and privacy compliance

### Technical Requirements

**Platform & Performance Requirements (Constitutional)**:
- **TR-023**: MUST support iOS 17.6+ as minimum platform requirement
- **TR-024**: MUST achieve app launch time under 2 seconds on target devices
- **TR-025**: MUST maintain main-thread I/O operations under 16ms
- **TR-026**: MUST provide adaptive UI for iPhone and iPad with proper scaling
- **TR-027**: MUST leverage iOS built-in encryption for therapeutic data security

**Data & Architecture Requirements**:
- **TR-028**: MUST use SwiftData with local SQLite backing for persistence
- **TR-029**: MUST design models for future CloudKit sync compatibility (user-controlled)
- **TR-030**: MUST implement proper SwiftUI state management with @Observable pattern
- **TR-031**: MUST ensure all CRUD operations work entirely offline
- **TR-032**: MUST provide audit trail logging for session access awareness

**Quality Gates (Constitutional)**:
- **TR-033**: MUST pass VoiceOver compliance testing for all views
- **TR-034**: MUST support Dynamic Type across all text elements
- **TR-035**: MUST maintain therapeutic tone - reflective and neutral, avoid clinical language
- **TR-036**: MUST ensure calming and supportive user interface design
- **TR-037**: MUST verify no external data collection or tracking capabilities

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can create and save a basic session entry in under 60 seconds
- **SC-002**: Users can access and view any past session in under 3 taps
- **SC-003**: App launches and displays session list in under 2 seconds on target devices (constitutional requirement)
- **SC-004**: All main-thread I/O operations complete in under 16ms (constitutional requirement)
- **SC-005**: Zero data loss during session entry, even with app interruption
- **SC-006**: Interface remains usable and accessible during altered states (large touch targets, clear text, simple navigation)
- **SC-007**: All session data persists locally without requiring internet connection

### Testing Success Criteria (MANDATORY)

- **TSC-001**: Achieve and maintain minimum 80% code coverage across all feature code
- **TSC-002**: 100% of public functions and methods covered by unit tests
- **TSC-003**: 100% of critical user workflows covered by UI tests (session creation, viewing, editing)
- **TSC-004**: All SwiftData models pass comprehensive unit testing including edge cases
- **TSC-005**: All ViewModels and services achieve 90%+ test coverage for business logic
- **TSC-006**: Integration tests verify 100% data persistence and retrieval accuracy
- **TSC-007**: Accessibility tests pass for all views with VoiceOver and Dynamic Type
- **TSC-008**: Performance tests confirm <2s app launch and <1s session list loading
- **TSC-009**: Error handling tests cover all failure scenarios with appropriate user feedback
- **TSC-010**: Security and privacy tests verify no unauthorized data access or leakage
- **TSC-011**: Therapeutic context tests ensure usability during altered states
- **TSC-012**: Test-first enforcement - no public API implementation without tests

### Key Entities

- **TherapySession**: Core entity representing a single therapy session with all associated data (date, treatment type, dose, intentions, environment, music, ratings, reflections)
- **TreatmentType**: Enumeration of treatment modalities (IV, IM, oral, lozenge, at-home, clinic)
- **MoodRating**: Rating scale from 1-10 or emoji representation for before/after session mood

### Governance & Compliance

**Constitutional Compliance**: This specification must adhere to all six constitutional principles:
1. **Privacy-First**: All session data remains local by default, user controls all sharing
2. **SwiftUI + SwiftData Native**: Modern Apple frameworks only, no UIKit unless required by system APIs  
3. **Therapeutic Value-First**: Every feature must directly support reflection and healing insights
4. **Offline-First Design**: Core functionality works without internet, optional cloud sync only
5. **Simplicity and Focus**: Essential therapeutic features only, avoid feature creep
6. **Test-Driven Quality**: Mandatory TDD with Red-Green-Refactor sequence

**Amendment Protocol**: Any changes to this specification require constitutional compliance review and documentation with clear rationale and impact assessment.

**Version**: 1.1.0 | **Last Updated**: 2025-11-05 | **Constitutional Compliance**: Required