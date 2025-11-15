# Backend / API Agent Playbook

Afterflow is currently offline-first with no public backend. This document preserves the rules that any future Claude, Codex, or Copilot automation must follow before introducing infrastructure beyond the iOS client.

## Current State
- There is **no server stack**; all data lives on-device via SwiftData.
- Any suggestion to add cloud sync or analytics must be explicitly approved and tied to a spec (likely future `specs/00x-*`).

## When Backend Work Is Authorized
1. Confirm a governing spec exists and is referenced in the PR/commit.
2. Extend `specs/<id>/` with API contracts before writing code.
3. Update `ai/globals/branching_strategy.md` if a new service repo or branch split is required.
4. Document privacy implications and opt-in flows inside the spec and PR.

## Guardrails
- No third-party telemetry or analytics libraries.
- Authentication must prefer OAuth2/PKCE if Spotify or similar integrations are involved.
- APIs must default to least privilege with encrypted transport and server-side logging that redacts therapeutic content.
- Follow `ai/workflows/feature_implementation.md` for change control even if the code lives outside this repo; link to any external repositories in the spec tasks.

## Deliverables Checklist
- [ ] Approved spec section describing the backend change.
- [ ] Data flow diagram or description stored in `specs/<id>/spec.md`.
- [ ] Security review findings documented (even if self-reviewed).
- [ ] Updated onboarding notes in `ai/README.md` or relevant agent file when backend capabilities go live.
