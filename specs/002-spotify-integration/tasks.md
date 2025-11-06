# Task List — Spotify Integration (v2)

## Phase 1 – OAuth PKCE Auth
- [ ] T201 [US1] Implement SpotifyAuthManager using AuthenticationServices.  
- [ ] T202 [US1] Generate PKCE code verifier + challenge per RFC 7636.  
- [ ] T203 [US1] Handle callback URL and parse tokens.  
- [ ] T204 [US1] Store access/refresh tokens securely in Keychain.  
- [ ] T205 [US1] Unit tests for PKCE flow, token handling, and refresh.  
- [ ] T206 [US1] Constitutional QA verification: accessibility, performance profiling, privacy compliance.  

## Phase 2 – Playlist Metadata Fetch
- [ ] T207 [US2] Create SpotifyService to call Web API (playlist-read-private).  
- [ ] T208 [US2] Parse playlist metadata: name, image, duration.  
- [ ] T209 [US2] Mock API + offline fallback.  
- [ ] T210 [US2] Unit tests for SpotifyService + offline cases.  
- [ ] T211 [US2] Constitutional QA verification: accessibility, performance profiling, privacy compliance.  

## Phase 3 – UI Flow
- [ ] T212 [US2] Build SpotifyConnectView with connect/disconnect buttons.  
- [ ] T213 [US2] Build SpotifyPlaylistPickerView with list + search.  
- [ ] T214 [US3] Add playlist display in SessionDetailView (art, name, duration).  
- [ ] T215 [US3] Deep link to Spotify using `spotify://` URI.  
- [ ] T216 [US2] Accessibility audit: reflective tone copy, labels, focus order.  
- [ ] T217 [US2] Constitutional QA verification: accessibility, performance profiling, privacy compliance.  

## Phase 4 – Integration with TherapySession
- [ ] T218 [US4] Extend TherapySession model with spotifyPlaylistURI/name/imageURL.  
- [ ] T219 [US4] Update SessionFormViewModel + persistence tests.  
- [ ] T220 [US4] Unit & UI tests for attach/detach playlist.  
- [ ] T221 [US4] Constitutional QA verification: accessibility, performance profiling, privacy compliance.  

## Phase 5 – QA & Governance
- [ ] T222 [Polish] Add “Disconnect Spotify” and clear-token logic.  
- [ ] T223 [Polish] Privacy manifest verification: no data collected.  
- [ ] T224 [Polish] Performance profiling: connect < 4 s, list < 500 ms.  
- [ ] T225 [Polish] Final QA review + governance sign-off.  
