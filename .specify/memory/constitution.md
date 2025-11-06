# Set and Setting Constitution

## Core Principles

### I. Privacy-First

Every feature must prioritize user privacy and data security. All sensitive therapeutic data remains on device by default. Any data sharing requires explicit user consent and clear purpose. No external analytics or tracking without user knowledge. All cloud sync operations must clearly label data scope and reversibility.

### II. SwiftUI + SwiftData Native

Build using modern Apple frameworks for consistency and performance. SwiftUI for all interfaces, SwiftData for local persistence. Leverage iOS capabilities while maintaining simplicity. No UIKit components unless required by system APIs.

### III. Therapeutic Value-First

Every feature must directly support therapeutic reflection and insights. User interface should be calming and supportive. No gamification or features that could encourage substance misuse. UI copy tone must be reflective and neutral—avoid clinical or diagnostic language.

### IV. Offline-First Design

Core functionality must work without internet connection. Optional cloud sync and integrations are enhancements, not dependencies. Users maintain full control over their data. Offline persistence is required for all CRUD operations.

### V. Simplicity and Focus

Start with essential features only. Each addition must serve a clear therapeutic purpose. Avoid feature creep that dilutes the core value proposition. Each release must pass a one-sentence purpose test: does this serve reflection or insight?

### VI. Test-Driven Quality (non-negotiable)

Every public interface must be test-first and measurable.

## Technical Constraints

### Platform Requirements

- **Minimum iOS Version**: ≥ 17.0 (tested on 17.6+)

- **Target Devices**: iPhone and iPad with adaptive UI

- **Architecture**: SwiftUI + SwiftData + CloudKit (optional)

- **Third-party Dependencies**: Minimal, only for essential integrations (Spotify SDK)

- **Performance Constraints**: Launch time <2s; main-thread I/O under 16ms.

### Data Management

- **Primary Storage**: SwiftData with local SQLite backing

- **Backup Strategy**: iCloud sync is user-controlled; backups remain local unless enabled.

- **Export Options**: CSV, PDF for sharing with therapists

- **Privacy**: No telemetry, no user tracking, no external data collection

### Security Standards

- **Biometric Protection**: Face ID/Touch ID for app access (optional but recommended)

- **Data Encryption**: Leverage iOS built-in encryption for local data

- **API Security**: OAuth 2.0 for Spotify integration only

- **Audit Trail**: Log session access for user awareness

### Development Workflow

### Test-Driven Development (mandatory)

- Use the Red-Green-Refactor sequence for all implementations.

- Write tests before implementation; ensure minimum 80% coverage.

- Unit tests for all SwiftData models, ViewModels, and Services.

- UI tests for all critical user workflows and acceptance scenarios.

- Integration tests for SwiftData persistence and complex workflows.

- Each pull request (PR) must reference its corresponding spec item and include a test evidence summary.

- No feature merges without meeting coverage and test requirements.

- No public function implementation without corresponding tests.

### Feature Implementation Order

1. Core session logging (offline) — no dependencies.

2. Local data persistence and viewing — depends on core session logging.

3. Export functionality — depends on local data persistence.

4. Spotify integration — optional, depends on local data persistence.

5. iCloud sync — depends on local data persistence.

6. Advanced analytics/insights — depends on export functionality and data persistence.

## Quality Gates

### User Experience

- All features must be accessible (VoiceOver, Dynamic Type).

- Interface should be calming and non-judgmental.

- UX tone review to ensure reflective and neutral communication.

- No dark patterns or manipulative design.

- Clear data ownership and control for users.

### Code Quality Gates

- **Test Coverage**: Minimum 80% code coverage before any feature merge.

- **Public API Coverage**: 100% test coverage required for all public functions and methods.

- **Test Types**: Unit tests (models, ViewModels, services), UI tests (user workflows), Integration tests (data persistence).

- **Test-First Enforcement**: No public function implementation without corresponding tests.

- **Performance**: Memory usage profiling, battery impact assessment.

- **Accessibility**: VoiceOver compliance, Dynamic Type support testing.

- **Privacy**: Local data encryption verification, no external data leakage testing.

## Governance

Constitution supersedes all other practices. Amendments require documentation and rationale. Privacy and therapeutic value principles are non-negotiable.

### Amendment Protocol

Amendments to this constitution must be proposed in writing with clear rationale and impact assessment. Proposals require review and approval by the governance committee. Approved amendments must be documented with versioning and date of ratification.

**Version**: 1.0.0 | **Ratified**: 2025-11-05 | **Last Amended**: 2025-11-05
