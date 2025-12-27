# Branching & Commit Strategy

Keeps Codex, Claude, and Copilot aligned when opening PRs or drafting local changes.

## Branch Names
- `main` stays releasable; no direct commits unless hotfix with approval.
- Feature branches: `feature/<short-slug>` (e.g., `feature/session-form`).
- Bugfix branches: `bugfix/<issue-id>-<slug>` (e.g., `bugfix/ios-171-auto-save`).
- Docs/process improvements: `chore/docs-<topic>`.

## Commit Messages
  - `feat(session): add reflection prompts`
  - `fix(services): harden auto-save timer reset`
  - `chore(docs): add AI onboarding index`
- Keep subjects ≤72 characters and body paragraphs wrapped at ~100 characters.

## Pull Request Requirements
- Reference the relevant issue and include a clear description of the changes.
- Include before/after screenshots for UI updates.
- Document privacy impact and confirm offline capability in the PR body.
- Checklist must state: tests run (`xcodebuild test ...`), coverage confirmed, and constitutional review done.

## Release Flow
1. Merge feature/bugfix branches into `main` via PR once checks pass.
2. Tag releases with semantic versions (`v0.2.0`) after verifying regression suite.

## Automation Hooks
- Copilot agents should avoid committing directly; rely on PR suggestions to keep history clean.
- Codex CLI automations must never run `git reset --hard`; rebase feature branches locally instead.
