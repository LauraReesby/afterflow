# AI Agent Control Center

Central reference for all automation agents working in Afterflow. Load this document first so everyone shares the same context and links into the deeper guides.

## Purpose & Vision

Afterflow is a **privacy-first, offline-first therapeutic session logging app** designed for individuals undergoing psychedelic-assisted therapy. 

Our mission is to provide a safe, private, and intuitive space for users to record:
- **Intentions**: What they hope to achieve or explore in a session.
- **Mood Changes**: Tracking emotional states before and after sessions.
- **Reflections**: Post-session insights and integration notes.
- **Music Context**: Linking playlists or tracks that accompanied the experience.

### Core Pillars
1. **Absolute Privacy**: No cloud sync, no tracking, no external data collection. Data belongs solely to the user.
2. **Therapeutic Value**: Every feature must serve the user's healing and integration process.
3. **Native Excellence**: Built with SwiftUI and SwiftData for a premium, reliable iOS experience.
4. **Offline Reliability**: Core functionality must work without an internet connection.

## Start Here Checklist
1. Read `.agent/globals/constitution.md` to align with privacy, therapeutic, and testing mandates.
2. Consult `AGENTS.md` for contributor etiquette, build commands, and testing guardrails.
3. Follow the shared globals and style guides for all implementations.

## Directory Index
- `.agent/agents/ios_dev.md` – Instructions for SwiftUI/SwiftData changes.
- `.agent/agents/backend.md` – Placeholder for future backend/API automation notes.
- `.agent/globals/style_guide.md` – Shared formatting, naming, and documentation standards.
- `.agent/globals/branching_strategy.md` – Branch naming, commit expectations, and PR metadata.
- `.agent/workflows/feature_implementation.md` – Step-by-step plan for shipping new features.
- `.agent/workflows/bugfix_flow.md` – Reduced workflow for hotfixes while preserving coverage and privacy proofs.

## External Guidance Map
| Need | File |
| --- | --- |
| Copilot runtime configuration | `.github/copilot/afterflow-agent.md` |
| Copilot slash commands | `.github/copilot/slash-commands.md` |
| Feature Implementation | `.agent/workflows/feature_implementation.md` |
| Bugfix Flow | `.agent/workflows/bugfix_flow.md` |
| Repository constitution | `.agent/globals/constitution.md` |

## Shared Expectations
- All agents must report how they satisfied the Constitution.
- Use the automation scripts in `/Scripts` for consistency (format, lint, build, run, and test all wrap `xcodebuild` with the right defaults).
- Format with `./Scripts/run-swiftformat.sh`, then lint with `./Scripts/run-swiftlint.sh` before marking tasks complete.
- Tests (`xcodebuild test -scheme Afterflow -destination 'platform=iOS Simulator,name=iPhone 16'`) run before marking tasks complete.
- Privacy and offline guarantees trump velocity—escalate if a request violates them.
