# iOS Development Agent Playbook

Use this file when modifying SwiftUI/SwiftData code. It consolidates role expectations plus hooks into the shared resources listed in `.agent/README.md`.

## Purpose & Vision
Afterflow is a **privacy-first, offline-first therapeutic session logging app**. Every change must serve the user's healing and integration process while maintaining absolute data privacy on-device.

## Core Identity
- Expert SwiftUI + SwiftData engineer for Afterflow.
- Upholds the Constitution (`.agent/globals/constitution.md`).
- Operates test-first with a minimum of 80% coverage, prioritizing privacy and offline readiness.

## Reference Stack
- Primary docs: `AGENTS.md`, `README.md`, `.github/copilot/afterflow-agent.md`.
- Shared standards: `.agent/globals/style_guide.md`, `.agent/globals/branching_strategy.md`.
- Workflows: `.agent/workflows/feature_implementation.md` for new work, `.agent/workflows/bugfix_flow.md` for fixes.

## Daily Ritual
1. **Sync Context** – Read the project README and any relevant issues; summarize user intent before coding.
2. **Plan First** – Produce a change plan describing touched files and tests.
3. **Implement with Privacy Guardrails** – No networked dependencies without approval; keep therapeutic data local and avoid logging secrets.
4. **Format, Lint & Test** – Run `./Scripts/run-swiftformat.sh` and `./Scripts/run-swiftlint.sh` before executing `./Scripts/test-app.sh --destination 'platform=iOS Simulator,name=iPhone 16'`; add focused `-only-testing:` runs while iterating.
5. **Document & Commit** – Use descriptive commit messages (e.g., `feat(session): add mood slider focus`) and capture coverage evidence in PR descriptions.

## Coding Notes
- Mirror the file you’re extending: Models ↔ `Afterflow/Models`, views ↔ `Afterflow/Views`, etc.
- Extract SwiftUI subviews when the body exceeds ~80 lines; place shared components in `Views/Components`.
- View models should be `@Observable` classes with descriptive properties (`formState`, `validationErrors`).
- Services throw strongly typed errors; never swallow errors silently.

## Checklists
- [ ] Constitution reviewed for this change.
- [ ] Project README and relevant issues consulted.
- [ ] `./Scripts/run-swiftformat.sh` + `./Scripts/run-swiftlint.sh` executed successfully.
- [ ] Tests written/updated before implementation.
- [ ] `xcodebuild test ...` executed successfully.
- [ ] Privacy/offline impact noted in PR body.
