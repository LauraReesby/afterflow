# Implementation Plan — Spotify Integration (v2)

## Overview
Integrate Spotify playlist linking into TherapeuticSession entries using secure OAuth PKCE flow and local token storage.

## Technical Context
**Language/Version:** Swift 5.9+ / iOS ≥ 17.6 (tested on 17.6+)  
**Frameworks:** SwiftUI, Foundation, AuthenticationServices  
**Storage:** Keychain for tokens, SwiftData for session fields  
**Testing:** TDD (Red-Green-Refactor) + XCTest + XCUITest  
**Performance Goal:** Connection < 4s; I/O < 16ms main thread; list display < 500ms  
**Privacy:** No playback, tracking, or cloud storage of user data.

## Architecture
```
Services/
 ├── SpotifyAuthManager.swift     # Handles PKCE OAuth, token refresh
 ├── SpotifyService.swift         # Fetches playlist metadata
ViewModels/
 ├── SpotifyViewModel.swift       # Connect/disconnect + selection
Views/
 ├── SpotifyConnectView.swift
 ├── SpotifyPlaylistPickerView.swift
 ├── SpotifyPlaylistCell.swift
 └── SpotifyDisconnectView.swift
Tests/
 ├── SpotifyAuthTests/
 ├── SpotifyServiceTests/
 └── SpotifyUITests/
```

## Phases
| Phase | Focus | Deliverables |
|-------|--------|--------------|
| 1 | OAuth PKCE Auth | SpotifyAuthManager + tests |
| 2 | Playlist Metadata Fetch | SpotifyService + mock API tests |
| 3 | UI Flow | ConnectView, PickerView, DisconnectView |
| 4 | Integration with TherapeuticSession | Add URI fields, update forms |
| 5 | QA & Governance | Privacy manifest, test validation |

## Metrics
- OAuth connect success ≥ 95 % in test runs.  
- No background API calls after disconnect.  
- QA review pass on accessibility + privacy.
