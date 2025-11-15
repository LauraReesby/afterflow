# Branching & Commit Strategy

Keeps Codex, Claude, and Copilot aligned when opening PRs or drafting local changes.

## Branch Names
- `main` stays releasable; no direct commits unless hotfix with approval.
- Feature branches: `feature/<spec-id>-<short-slug>` (e.g., `feature/001-session-form`).
- Bugfix branches: `bugfix/<issue-id>-<slug>` (e.g., `bugfix/ios-171-auto-save`).
- Docs/process improvements: `chore/docs-<topic>`.

## Commit Messages
- Use conventional commits plus spec references when applicable:
  - `feat(session): add reflection prompts (001-core-session-logging)`
  - `fix(services): harden auto-save timer reset`
  - `chore(docs): add AI onboarding index`
- Keep subjects ≤72 characters and body paragraphs wrapped at ~100 characters.

## Pull Request Requirements
- Reference the spec/task and link relevant `specs/<id>/tasks.md` checklist items.
- Include before/after screenshots for UI updates.
- Document privacy impact and confirm offline capability in the PR body.
- Checklist must state: tests run (`xcodebuild test ...`), coverage confirmed, and constitutional review done.

## Release Flow
1. Merge feature/bugfix branches into `main` via PR once checks pass.
2. Tag releases with semantic versions (`v0.2.0`) after verifying regression suite.
3. Update `specs/<id>/plan.md` with release notes or outstanding tasks as part of the merge.

## Automation Hooks
- Copilot agents should avoid committing directly; rely on PR suggestions or apply_patch to keep history clean.
- Codex CLI automations must never run `git reset --hard`; rebase feature branches locally instead.
- Claude/SpecKit tasks should annotate the relevant branch name when generating implementation checklists to keep humans informed.
