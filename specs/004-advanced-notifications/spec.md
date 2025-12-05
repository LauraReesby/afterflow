# Advanced Notifications (001-AN)

## Goal
Enhance reminder notifications so tapping a notification deep-links into the correct session, and long-press (notification action) lets the user capture a quick reflection without fully opening the app.

## Scope
- Foreground and background handling of reminder notifications with session deep links.
- Notification category/actions to support quick reflection entry from the notification (long press / expanded actions).
- Persistence of reflection input into the correct `TherapeuticSession`.
- Accessibility and privacy considerations (no PII in notification payload; minimal data in userInfo).

## Requirements
1. **Session Deep Link**
   - Tapping a reminder notification opens Afterflow and navigates directly to the matching `TherapeuticSession` detail.
   - If the session was deleted, show a gentle error and fall back to the session list.
   - Support cold start and warm app states (app backgrounded).

2. **Quick Reflection Action**
   - Long-press (or swipe) on a reminder notification shows an action to “Add Reflection”.
   - On selection, present a text input from the notification (UNTextInputNotificationAction).
   - Persist the entered reflection onto the correct `TherapeuticSession` (default: prepend a timestamped entry; configurable later).
   - Confirm success with a minimal in-app toast when the app next opens.

3. **User Experience**
   - Friendly copy: Title remains neutral (“Needs Reflection”); body avoids sensitive details.
   - VoiceOver: Actions labeled, easy to find in notification actions.
   - Error handling: If reflection save fails (e.g., model unavailable), queue the text locally and prompt to retry on next launch.

4. **Security & Privacy**
   - No sensitive data in notification payload beyond `sessionID` (UUID) and a neutral title/body.
   - No network usage; all persistence is local.
   - Input from notification is stored immediately in SwiftData; if app is not running, queue in extension and apply on next launch.

5. **Performance**
   - Deep link navigation should occur within 1s after app becomes active.
   - Reflection save from notification should take <300ms when app is running; offline queue replay <1s on launch.

## Open Questions
- Should reflection input replace existing text or prepend with a timestamp bullet? (Default proposal: prepend timestamped entry.)
- Do we want a “Dismiss” action alongside “Add Reflection” for clarity?
- Should we support multiple reminders/actions per session (e.g., recurring reminders)?

