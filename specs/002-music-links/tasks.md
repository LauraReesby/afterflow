# Task List — Music Link Integration (v2)

_Status reset 2025‑11‑29: pivoted from Spotify-only OAuth to general playlist links with tiered provider support._

## Phase 1 – Metadata Pipeline
- [ ] T201 [US1] Implement `MusicLinkMetadataService` URL normalization + provider classification (Spotify, YouTube, SoundCloud, Other).  
- [ ] T202 [US1] Fetch oEmbed metadata for Tier‑1 providers (Spotify + YouTube) with timeout/retry logic.  
- [ ] T203 [US1] Provide graceful fallback + caching when metadata fails (store raw URL + provider label).  
- [ ] T204 [US1] Unit tests covering classification, oEmbed decoding, and error handling.  
- [ ] T205 [US1] QA verification: privacy (no tokens), accessibility of copy, performance profiling (<3 s fetch).  

## Phase 2 – Session Form UX
- [ ] T206 [US1] Add “Playlist Link” input row with validation status + provider badge, including edit/replace and clear actions.  
- [ ] T207 [US1] Wire input row to metadata service (auto-fetch on paste, retry CTA, loading indicators).  
- [ ] T208 [US1] Persist normalized metadata in `TherapeuticSession` + SessionStore, including remove-link action.  
- [ ] T209 [US1] XCUITests for adding/removing playlist links on the form.  

## Phase 3 – Session Detail UX
- [ ] T210 [US2] Build `MusicLinkCardView` showing title, provider icon, thumbnail (if available), and fallback copy.  
- [ ] T211 [US2] Add “Open playlist” deep link with scheme-aware fallback + remove action on SessionDetailView.  
- [ ] T212 [US2] UI/VoiceOver polish + snapshot/UI tests for the card states (Tier‑1 preview vs link-only).  

## Phase 4 – Extended Providers
- [ ] T213 [US3] Enable Tier‑2 provider (SoundCloud) via the same oEmbed pipeline, gated behind a configuration flag.  
- [ ] T214 [US3] Add copy variants for link-only services (Apple Music, Bandcamp, Tidal, Deezer, custom).  
- [ ] T215 [US3] Regression/UI tests covering Tier‑2 + link-only messaging.  

## Phase 5 – QA & Governance
- [ ] T216 [Polish] Final accessibility + privacy audit (no playback, no analytics).  
- [ ] T217 [Polish] Documentation & README updates describing supported tiers + usage.  
- [ ] T218 [Polish] Performance profiling (metadata fetch < 3 s; UI thread budget < 16 ms).  
- [ ] T219 [Polish] Release readiness + governance sign-off.  
