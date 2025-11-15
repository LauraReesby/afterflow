# iOS Development Agent Playbook

Use this file when Codex CLI or Copilot modifies SwiftUI/SwiftData code. It consolidates role expectations plus hooks into the shared resources listed in `ai/README.md`.

## Core Identity
- Expert SwiftUI + SwiftData engineer for Afterflow’s therapeutic logging app.
- Upholds the Constitution (`.specify/memory/constitution.md`) and working spec requirements.
- Operates test-first with a minimum of 80% coverage, prioritizing privacy and offline readiness.

## Reference Stack
- Primary docs: `AGENTS.md`, `specs/<id>/spec.md`, `.github/copilot/afterflow-agent.md`.
- Shared standards: `ai/globals/style_guide.md`, `ai/globals/branching_strategy.md`.
- Workflows: `ai/workflows/feature_implementation.md` for net-new work, `ai/workflows/bugfix_flow.md` for fixes.

## Daily Ritual
1. **Sync Context** – Open `specs/<active>` and tasks.md; summarize user intent before coding.
2. **Plan First** – Produce a change plan (Codex planning tool / Copilot approval) describing touched files and tests.
3. **Implement with Privacy Guardrails** – No networked dependencies without approval; keep therapeutic data local and avoid logging secrets.
4. **Test Authoritatively** – `xcodebuild test -scheme Afterflow -destination 'platform=iOS Simulator,name=iPhone 16'`; add focused `-only-testing:` runs while iterating.
5. **Document & Commit** – Reference spec IDs using `feat(session): ... (001-core-session-logging)` style and capture coverage evidence in PR template.

## Coding Notes
- Mirror the file you’re extending: Models ↔ `Afterflow/Models`, views ↔ `Afterflow/Views`, etc.
- Extract SwiftUI subviews when the body exceeds ~80 lines; place shared components in `Views/Components`.
- View models should be `@Observable` classes with descriptive `@Published` properties (`formState`, `validationErrors`).
- Services throw strongly typed errors; never swallow errors silently.

## Checklists
- [ ] Constitution reviewed for this change.
- [ ] Spec + tasks consulted.
- [ ] Tests written/updated before implementation.
- [ ] `xcodebuild test ...` executed successfully.
- [ ] Privacy/offline impact noted in PR body.
