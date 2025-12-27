# Backend / API Agent Playbook

Afterflow is currently offline-first with no public backend. This document preserves the rules that any future automation must follow before introducing infrastructure beyond the iOS client.

## Current State
- There is **no server stack**; all data lives on-device via SwiftData.
- Any suggestion to add cloud sync or analytics must be explicitly approved and documented in the project README or a dedicated architectural proposal.

## When Backend Work Is Authorized
1. Confirm the architectural change is approved and documented.
2. Define API contracts and data flows before writing code.
3. Update `.agent/globals/branching_strategy.md` if a new service repo or branch split is required.
4. Document privacy implications and opt-in flows in the PR and technical documentation.

## Guardrails
- No third-party telemetry or analytics libraries.
- Authentication must prefer OAuth2/PKCE if Spotify or similar integrations are involved.
- APIs must default to least privilege with encrypted transport and server-side logging that redacts therapeutic content.
- Follow the project's shared globals, style guides, and workflows (`.agent/workflows/`) for all implementations.

## Deliverables Checklist
- [ ] Approved architectural proposal describing the backend change.
- [ ] Data flow diagram or description included in technical documentation.
- [ ] Security review findings documented (even if self-reviewed).
- [ ] Updated onboarding notes in `.agent/README.md` or relevant agent file when backend capabilities go live.
