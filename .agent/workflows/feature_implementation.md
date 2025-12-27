# Feature Implementation Workflow

Applies to any new capability. Follow this exact order to ensure constitutional compliance and quality.

1. **Intake & Alignment**
   - Read `.agent/README.md`, the project README, and `.agent/globals/constitution.md`.
   - Review relevant issues for requirements, performance targets, and success metrics.
   - Confirm the task’s acceptance criteria.
2. **Change Plan**
   - Outline affected files, data flows, and planned tests.
   - Share the plan for approval (e.g., via a plan comment or planning tool).
3. **Implementation**
   - Work inside matching folders (`Afterflow/Models`, `Services`, `Views`, `ViewModels`).
   - Reference `.agent/globals/style_guide.md` for formatting and naming.
   - Keep commits incremental and descriptive.
4. **Testing & Validation**
   - Run `./Scripts/run-swiftformat.sh` and `./Scripts/run-swiftlint.sh`; fix any violations before testing.
   - Write/execute unit + UI tests via `xcodebuild test -scheme Afterflow -destination 'platform=iOS Simulator,name=iPhone 16'`.
   - Use `-only-testing:` flags for fast iteration but always finish with the full suite.
   - Record coverage evidence (≥80%).
   - Complete the applicable “Constitutional QA verification” checks (accessibility, performance profiling, privacy compliance) before moving on.
5. **Documentation & Review**
   - Update relevant documentation when behavior changes.
   - Summarize privacy/offline considerations and attach screenshots for UI work.
   - Ensure PR references relevant issues and completed checklist items.
6. **Handoff**
   - Suggest next steps or follow-up tasks.
