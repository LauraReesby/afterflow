# Feature Spec — Music Link Integration (v2)
**Feature ID:** 002  
**Status:** Active  
**Depends On:** Core Session Logging (001)  
**Constitution Reference:** v1.0.0  
**Owner:** Engineering + Product  

## Intent
Let users attach calming playlist links (Spotify, YouTube, etc.) to a session without forcing authentication, while surfacing safe previews for supported services.

## Problem
Music is central to the therapeutic setting, yet users can’t easily log what they listened to without manual text entry.

## Success Criteria
- Accept a playlist URL from popular services and attach it to any TherapeuticSession.
- Tier‑1 URLs (Spotify, YouTube) automatically fetch preview metadata via oEmbed (title + thumbnail).
- Tier‑2 services (SoundCloud) reuse the same pipeline later if needed.
- Link-only services (Apple Music, Bandcamp, Tidal, Deezer, custom) still store the URL and show a graceful fallback card.
- No OAuth, logins, or playback—only metadata fetches and deep links out.
- **Performance**: metadata fetch < 3 s; UI remains responsive even if parsing fails.

---

## User Stories
### US1 — Add a Music Link
**As a user**, I want to paste a playlist link into the session form so I don’t forget the soundtrack later.  
**Acceptance**
1. App validates the URL and classifies it (Tier‑1/Tier‑2/link-only/unknown).  
2. Tier‑1 URLs trigger an oEmbed fetch and show metadata inline.  
3. Unsupported URLs are still stored with descriptive fallback messaging.  

### US2 — View Playlist Preview
**As a user**, I want to see the playlist name/artwork in the session detail view and open it externally.  
**Acceptance**
1. SessionDetailView displays the stored metadata (title, provider, thumbnail if available).  
2. Tapping “Open playlist” deep links to the original URL using `UIApplication.shared.open`.  
3. If metadata is missing, the card falls back to “Open playlist link” with the raw URL.  

### US3 — Update or Remove Music Link
**As a user**, I want to change or clear the playlist if plans shift.  
**Acceptance**
1. Form allows pasting a new URL; existing metadata is replaced when saved.  
2. A “Remove link” action clears metadata/URL from the session.  
3. Validation ensures only one link per session.  

---

## Functional Requirements
| ID | Requirement |
|----|--------------|
| FR-201 | Parse and validate playlist URLs from user input; classify provider (Spotify, YouTube, SoundCloud, other). |
| FR-202 | For Tier‑1 providers (Spotify, YouTube) call their public oEmbed endpoints to retrieve title + thumbnail + author/provider metadata. |
| FR-203 | Cache fetched metadata in memory for the current editing session to avoid duplicate calls. |
| FR-204 | Persist the normalized URL plus display fields inside TherapeuticSession (repurpose existing playlist fields as generic music link fields). |
| FR-205 | Fallback gracefully if oEmbed fails (network error, unsupported provider) by storing the raw URL and showing safe copy. |
| FR-206 | Surface a playlist card in SessionDetailView with accessible labels and an “Open playlist” button that launches the stored URL via `UIApplication.open`. If the provided scheme cannot be opened, fall back to an HTTPS URL when available and surface an error toast if both fail. |
| FR-207 | Provide a “Remove Link” action that clears metadata and URL in both form and detail views. |
| FR-208 | Support copy/paste interactions only; no authentication, background refresh, or playback. Allow users to edit the existing link inline (replacing metadata on save). |

---

## Technical Requirements
| ID | Description |
|----|--------------|
| TR-201 | Create a `MusicLinkMetadataService` that performs HTTP(S) requests (oEmbed) with 3‑second timeout and JSON decoding. |
| TR-202 | Tier‑1 providers: Spotify (`https://open.spotify.com/oembed`) and YouTube (`https://www.youtube.com/oembed`). Tier‑2 (SoundCloud) shares the same service but can be feature‑flagged later. |
| TR-203 | All other providers fall back to link-only mode; never attempt scraping or unofficial APIs. |
| TR-204 | No OAuth, tokens, or refresh logic required. |
| TR-205 | SwiftUI UI additions: inline link input row, metadata preview card, and remove-link confirmation. |
| TR-206 | Unit tests cover URL parsing, classification, and metadata decoding; UI tests verify adding/removing links and fallback behavior. |
| TR-207 | Performance: metadata fetch must finish < 3 seconds or display an error with retry CTA; UI thread budget < 16 ms. |

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
- **Integration-Specific**: Metadata fetch accuracy, link validation, attaching/removing workflows.
- **Privacy-Specific**: Only store user-provided URLs and oEmbed metadata; no analytics or tracking pixels.

---

## Risks & Mitigation
| Risk | Mitigation |
|------|-------------|
| oEmbed rate limits or downtime | Cache last fetched metadata per session and allow manual retry/fallback message. |
| Unsupported providers | Always show link-only state so the session still references the playlist. |
| Thumbnail reuse compliance | Use returned thumbnail URLs directly without rehosting; respect provider branding guidance. |

---

## Dependencies
- Spotify & YouTube public oEmbed endpoints
- Core Session Logging (001)

---

## Amendment Notes
Feature changes require governance committee review.

## UI Details
- **Music Row**: beneath the existing notes field, add a “Playlist Link” input with validation and Tier indicator (Spotify, YouTube, SoundCloud, Link-only). Editing the text field replaces the stored link once the form is saved.
- **Metadata Preview**: show fetched title, provider icon, and thumbnail (Tier‑1/2) with remove button.
- **Session Detail Card**: display saved metadata or fallback link copy plus an “Open playlist” button that tries the provider’s native app first and then HTTPS fallback.
- **Error States**: copy such as “Couldn’t fetch preview, saved the link instead” with a retry CTA.
