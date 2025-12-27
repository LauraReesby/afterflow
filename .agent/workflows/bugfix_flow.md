# Bugfix Workflow

Use this flow for production regressions or test failures without new feature scope.

1. **Triage**
   - Capture the issue ID and confirm affected area.
   - Review the expected behavior and any performance thresholds that might be impacted.
   - Document the failure in the issue body.
2. **Scope & Safeguard**
   - Identify reproduction steps and failing tests.
   - Create a `bugfix/<issue-id>-<slug>` branch per `.agent/globals/branching_strategy.md`.
3. **Plan**
   - Produce a minimal change plan noting files touched and tests to add/regressions to cover.
   - Highlight any privacy or data migration impact up front.
4. **Fix & Test**
   - Run `./Scripts/run-swiftformat.sh` and `./Scripts/run-swiftlint.sh` to ensure new code meets formatting rules.
   - Write a regression test first; confirm it fails.
   - Apply the fix respecting the style guide; keep logs private-safe.
   - Run `xcodebuild test -scheme Afterflow -destination 'platform=iOS Simulator,name=iPhone 16'` plus any targeted suites.
   - Repeat any constitutional QA checks that could have regressed (accessibility, privacy, performance) and capture evidence.
5. **Review Package**
   - Update documentation only if the bug reveals a requirement gap.
   - Fill PR checklist: repro summary, fix description, tests, privacy impact, screenshots if UI.
   - Reference the issue ID in commit message (`fix(session): restore mood slider focus (#123)`).
6. **Verification & Closeout**
   - Ensure the regression test now passes and would fail without the fix.
   - Mark the issue/task as ✅ only after merge.
