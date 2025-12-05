# Plan — Advanced Notifications (001-AN)

## Overview
Enable deep-link handling from reminder notifications and support a quick reflection input action directly from the notification (UNTextInputNotificationAction), while keeping privacy intact and latency low.

## Steps
1) **Deep Link Plumbing**
   - Register notification categories (with/without quick-action) and set UNUserNotificationCenter delegate.
   - Read `sessionID` from `userInfo` and route to SessionDetail (cold/warm start handling).
   - Graceful fallback if session missing (show list + alert/toast).

2) **Quick Reflection Action**
   - Add "Add Reflection" text input action; wire to a handler that persists to SwiftData.
   - Default behavior: prepend timestamped entry to existing reflections.
   - If app not running/DB unavailable, queue the input and replay on next launch.

3) **State & UX**
   - Navigation state to push SessionDetail from notification tap.
   - Toast/banner on next launch to confirm queued reflection save.
   - Neutral copy and VoiceOver labels for actions.

4) **Testing & Perf**
   - Unit tests for routing, missing session, and reflection appends.
   - UI tests for notification action where possible; otherwise injectable harness.
   - Perf checks: deep link <1s after activation; reflection save <300ms; replay <1s.

5) **Governance & Privacy**
   - Verify payload contains only sessionID and neutral text; no network.
   - Document retention of queued reflections; ensure purge after apply.

## Deliverables
- Notification delegate and routing logic (App/Scene layer).
- UNNotificationCategory with text input action and handler.
- Persistence path for reflection input (live + queued).
- Tests and QA notes covering perf, accessibility, and privacy.

