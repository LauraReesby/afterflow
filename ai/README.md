# AI Agent Control Center

Central reference for all automation agents working in Afterflow. Load this document first whether you are Codex (CLI), Claude (SpecKit), or GitHub Copilot so everyone shares the same context and links into the deeper guides.

## Start Here Checklist
1. Read `.specify/memory/constitution.md` to align with privacy, therapeutic, and testing mandates.
2. Review the active spec in `specs/<id>-*/` plus the matching tasks.md for work-in-progress requirements.
3. Consult `AGENTS.md` for contributor etiquette, build commands, and testing guardrails.
4. Pick the agent playbook below that matches your tool and follow its workflow plus the shared globals.

## Directory Index
- `ai/agents/ios_dev.md` – Codex CLI & Copilot instructions for SwiftUI/SwiftData changes.
- `ai/agents/backend.md` – Placeholder for future backend/API automation notes.
- `ai/globals/style_guide.md` – Shared formatting, naming, and documentation standards.
- `ai/globals/branching_strategy.md` – Branch naming, commit expectations, and PR metadata.
- `ai/workflows/feature_implementation.md` – Step-by-step plan for shipping new stories under SpecKit.
- `ai/workflows/bugfix_flow.md` – Reduced workflow for hotfixes while preserving coverage and privacy proofs.

## External Guidance Map
| Need | File |
| --- | --- |
| Copilot runtime configuration | `.github/copilot/afterflow-agent.md` |
| Copilot slash commands | `.github/copilot/slash-commands.md` |
| Claude/SpecKit prompt pack | `.github/prompts/*.prompt.md` |
| Repository constitution | `.specify/memory/constitution.md` |
| Product specs & TODOs | `specs/001-core-session-logging/`, `specs/002-spotify-integration/`, `specs/003-data-export/` |

## Agent Profiles
- **Codex CLI** – Use `ai/agents/ios_dev.md` plus the Feature/Bugfix workflows. Keep terminal/test commands aligned with `AGENTS.md` and mirror file structure when editing.
- **Claude (SpecKit)** – Load this README, then the relevant workflow. SpecKit prompts in `.github/prompts/` remain authoritative for slash commands.
- **GitHub Copilot** – Configure `.github/copilot/agents.json` and `afterflow-agent.md` but treat this README as the canonical index of supporting material.

## Shared Expectations
- All agents must report how they satisfied the Constitution and cite specs/sections touched.
- Tests (`xcodebuild test -scheme Afterflow -destination 'platform=iOS Simulator,name=iPhone 16'`) run before marking tasks complete.
- Privacy and offline guarantees trump velocity—escalate if a request violates them.
