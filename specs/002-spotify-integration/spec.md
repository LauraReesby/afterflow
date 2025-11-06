# Feature Spec — Spotify Integration (v2)
**Feature ID:** 002  
**Status:** Active  
**Depends On:** Core Session Logging (001)  
**Constitution Reference:** v1.0.0  
**Owner:** Engineering + Product  

## Intent
Let users attach a Spotify playlist or track link to a session for context during or after therapy, keeping privacy and control.

## Problem
Music is central to therapeutic setting, yet users can’t easily log what they listened to without manual text entry.

## Success Criteria
- Link Spotify playlists or tracks to any TherapySession.
- No in-app playback or analytics.
- OAuth login fully transparent; tokens stored locally.
- UI shows playlist name, cover art, duration.
- Logout and token deletion available at any time.
- **Performance**: OAuth flow < 15s; playlist fetch < 3s; UI remains responsive.

---

## User Stories
### US1 — Connect Spotify
**As a user**, I want to securely connect my Spotify account to retrieve my playlists.  
**Acceptance**
1. “Connect Spotify” button triggers OAuth PKCE flow.  
2. Consent screen explains scopes (`playlist-read-private`, `user-read-email`).  
3. After success, only playlist metadata stored locally.

### US2 — Attach Playlist
**As a user**, I want to attach a playlist to a session.  
**Acceptance**
1. Playlist list fetched locally after connection.  
2. User can choose one playlist per session.  
3. Playlist metadata displayed in SessionDetailView.  

### US3 — View Playlist Info
**As a user**, I want to see which playlist I used.  
**Acceptance**
1. SessionDetailView shows playlist name, art, duration.  
2. Tap “Open in Spotify” → deep link to Spotify app.  

### US4 — Disconnect
**As a user**, I want to revoke access.  
**Acceptance**
1. “Disconnect Spotify” removes tokens & metadata.  
2. Session data remains intact; playlist field cleared.

---

## Functional Requirements
| ID | Requirement |
|----|--------------|
| FR-201 | Implement Spotify OAuth 2.0 (PKCE) flow. |
| FR-202 | Store access/refresh tokens in Keychain. |
| FR-203 | Fetch playlist metadata (name, image, duration). |
| FR-204 | Allow user to link one playlist per TherapySession. |
| FR-205 | Deep link to Spotify via `spotify://` or HTTPS. |
| FR-206 | Provide disconnect & token wipe functionality. |
| FR-207 | Respect offline mode (defer connection gracefully). |

---

## Technical Requirements
| ID | Description |
|----|--------------|
| TR-201 | SwiftUI 5.9 interface additions on iOS ≥ 17.6: Connect, Choose Playlist, Disconnect. |
| TR-202 | Spotify Web API endpoints only; no SDK dependency for minimal attack surface. |
| TR-203 | Token storage: iOS Keychain (secure). |
| TR-204 | Added fields to `TherapySession`: `spotifyPlaylistURI`, `spotifyPlaylistName`, `spotifyPlaylistImageURL`. |
| TR-205 | ViewModel isolation: `SpotifyService` + `SpotifyAuthManager`. |
| TR-206 | UI: reflective tone, avoid "music recommendation" language. |
| TR-207 | Performance: launch < 2s; I/O < 16ms main thread (constitutional requirements). |

---

## QA Standards
**Constitutional Quality Gates (non-negotiable):**
- **Test Coverage**: Minimum 80% code coverage before any feature merge.
- **Public API Coverage**: 100% test coverage required for all public functions and methods.
- **Test-Driven Development (TDD)**: Red-Green-Refactor sequence mandatory for all public interfaces.
- **Accessibility**: VoiceOver compliance, Dynamic Type support testing.
- **Performance**: Memory usage profiling, battery impact assessment.
- **Privacy**: Local data encryption verification, no external data leakage testing.
- **UX Standards**: Calming, non-judgmental interface; reflective and neutral communication tone.
- **Integration-Specific**: Token storage security, metadata fetch accuracy, linking/unlinking workflows.
- **Privacy-Specific**: No Spotify analytics events or telemetry allowed.

---

## Risks & Mitigation
| Risk | Mitigation |
|------|-------------|
| Token misuse | Store tokens only in Keychain; auto-expire on logout. |
| Privacy perception | Clear consent copy; no background network after connect. |
| API change | Use lightweight wrapper with fallback message. |

---

## Dependencies
- Spotify Web API (OAuth 2.0 PKCE)
- Core Session Logging (001)

---

## Amendment Notes
Feature changes require governance committee review.
