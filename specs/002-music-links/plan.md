# Implementation Plan — Music Link Integration (v2)

## Overview
Capture and display playlist links inside TherapeuticSession entries without any third-party authentication. Tier‑1 providers (Spotify, YouTube) use their public oEmbed endpoints to render calming previews; Tier‑2 (SoundCloud) can be added behind the same service when needed. All other providers fall back to a simple “Open playlist link” card.

## Technical Context
**Language/Version:** Swift 5.9+ / iOS ≥ 17.6  
**Frameworks:** SwiftUI, Foundation  
**Networking:** URLSession (oEmbed JSON)  
**Storage:** SwiftData fields on `TherapeuticSession` (repurposed for music link metadata)  
**Testing:** XCTest (unit/service) + XCUITest for end-to-end link workflows  
**Performance Goal:** Metadata fetch < 3 s; UI work < 16 ms on main thread  
**Privacy:** Only fetch metadata for user-supplied URLs; no tokens, analytics, or playback.

## Architecture
```
Services/
 └── MusicLinkMetadataService.swift   # URL classifier + oEmbed fetcher
ViewModels/
 ├── MusicLinkViewModel.swift         # Handles form input, fetch, caching
 └── MusicLinkCardViewModel.swift     # Drives read-only detail preview
Views/
 ├── MusicLinkInputRow.swift          # TextField + status indicator + remove
 └── MusicLinkCardView.swift          # Title/thumbnail/button in detail view
Tests/
 ├── MusicLinkMetadataServiceTests/
 ├── MusicLinkViewModelTests/
 └── MusicLinkUITests/
```

## Flow Summary
1. **Paste Link** – User pastes or types a playlist URL into the new “Playlist Link” field on SessionFormView. View model validates and classifies the provider.
2. **Fetch Metadata** – For Tier‑1 URLs, `MusicLinkMetadataService` calls the provider’s oEmbed endpoint and returns normalized metadata (title, author, thumbnail URL). Failures fall back to storing just the URL plus provider name if known.
3. **Save Session** – SessionStore persists the normalized URL and metadata. Only one link per session is supported; replacing the link overwrites fields.
4. **View Detail** – SessionDetailView shows the playlist card. If metadata exists, display title + thumbnail. The “Open playlist” button launches the stored URL via `UIApplication.shared.open`; if the scheme cannot be opened, fall back to a sanitized HTTPS version and surface an error state if both fail.
5. **Remove Link** – Both form and detail surfaces expose “Remove link” which clears stored metadata/URL.

## Phases
| Phase | Focus | Deliverables |
|-------|-------|--------------|
| 1 | Metadata Foundation | MusicLinkMetadataService (classification + oEmbed) + unit tests |
| 2 | Session Form UX | Playlist Link input row, inline validation, fetch/retry, remove action |
| 3 | Session Detail UX | Metadata card, fallback messaging, open button, remove action |
| 4 | Extended Providers | Optional SoundCloud (Tier‑2) wiring + link-only copy polish |
| 5 | QA & Governance | Accessibility audit, privacy review, documentation updates |

## Metrics
- Metadata fetch success rate ≥ 95 % for Tier‑1 links under healthy network conditions.  
- Fallback copy shown within 3 s if a provider cannot be resolved.  
- UI tests cover add/remove flows plus Tier‑1 preview rendering.  
- Manual QA verifies copy tone + VoiceOver order across card + input row.
