# Feature Implementation Workflow

Applies to any new capability driven by `specs/<id>-*/`. Follow this exact order whether you are Codex, Claude, or Copilot.

1. **Intake & Alignment**
   - Read `ai/README.md`, the governing spec, and `.specify/memory/constitution.md`.
   - Review `specs/<id>/plan.md` for performance targets, milestones, and success metrics.
   - Confirm the task’s acceptance criteria (and outstanding ✅ items) in `specs/<id>/tasks.md`.
2. **Change Plan**
   - Outline affected files, data flows, and planned tests.
   - Share the plan for approval (Codex planning tool, Copilot plan comment, or Claude Clarify prompt).
3. **Implementation**
   - Work inside matching folders (`Afterflow/Models`, `Services`, `Views`, `ViewModels`).
   - Reference `ai/globals/style_guide.md` for formatting and naming.
   - Keep commits incremental and reference the spec ID.
4. **Testing & Validation**
   - Write/execute unit + UI tests via `xcodebuild test -scheme Afterflow -destination 'platform=iOS Simulator,name=iPhone 16'`.
   - Use `-only-testing:` flags for fast iteration but always finish with the full suite.
   - Record coverage evidence (≥80%) plus any measurements tied to the spec’s performance goals.
   - Complete the applicable “Constitutional QA verification” checks from `specs/<id>/tasks.md` (accessibility, performance profiling, privacy compliance) before moving on.
5. **Documentation & Review**
   - Update the relevant `specs/<id>/plan.md` or `spec.md` sections when behavior changes.
   - Summarize privacy/offline considerations and attach screenshots for UI work.
   - Ensure PR references branch, spec ID, and completed checklist items from `AGENTS.md`.
6. **Handoff**
   - Suggest next steps or follow-up tasks.
   - Mark `tasks.md` entries with ✅ only after merge-ready validation and the corresponding QA verification notes are captured in the PR or spec.
