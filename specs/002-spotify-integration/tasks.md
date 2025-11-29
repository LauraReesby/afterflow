# Task List — Spotify Integration (v2)

## Phase 1 – OAuth PKCE Auth
- [x] T201 [US1] Implement SpotifyAuthManager using AuthenticationServices.  
- [x] T202 [US1] Generate PKCE code verifier + challenge per RFC 7636.  
- [x] T203 [US1] Handle callback URL parameters + token exchange helpers.  
- [x] T204 [US1] Store access/refresh tokens securely in Keychain.  
- [x] T205 [US1] Unit tests for PKCE flow + SecureStore.  
- [x] T206 [US1] Constitutional QA verification: accessibility, performance profiling, privacy compliance.  

## Phase 2 – Playlist Metadata Fetch
- [x] T207 [US2] Create SpotifyService to call Web API (playlist-read-private).  
- [x] T208 [US2] Parse playlist metadata: name, image, duration/track count.  
- [x] T209 [US2] Mock API + offline fallback.  
- [x] T210 [US2] Unit tests for SpotifyService + offline cases.  
- [ ] T211 [US2] Constitutional QA verification: accessibility, performance profiling, privacy compliance.  

## Phase 3 – UI Flow
- [ ] T212 [US2] Build SpotifyConnectView with connect/disconnect buttons + explanatory copy.  
- [ ] T212a [US2] Embed Spotify badge button inside SessionForm/Detail “Music” rows (connect vs. select states).  
- [ ] T213 [US2] Build SpotifyPlaylistPickerView with list + search.  
- [ ] T214 [US3] Add playlist display in SessionDetailView (art, name, duration).  
- [ ] T214a [US3] Playlist picker integration with SessionFormView/SessionDetailView (attach/detach flows).  
- [ ] T215 [US3] Deep link to Spotify using `spotify://` URI (fallback HTTPS).  
- [ ] T216 [US2] Accessibility audit: reflective tone copy, labels, focus order.  
- [ ] T217 [US2] Constitutional QA verification: accessibility, performance profiling, privacy compliance.  

## Phase 4 – Integration with TherapeuticSession
- [x] T218 [US4] Extend TherapeuticSession model with spotifyPlaylistURI/name/imageURL.  
- [ ] T219 [US4] Update SessionFormViewModel + persistence tests.  
- [ ] T220 [US4] Unit & UI tests for attach/detach playlist.  
- [ ] T221 [US4] Constitutional QA verification: accessibility, performance profiling, privacy compliance.  

## Phase 5 – QA & Governance
- [ ] T222 [Polish] Add “Disconnect Spotify” and clear-token logic.  
- [ ] T223 [Polish] Privacy manifest verification: no data collected.  
- [ ] T224 [Polish] Performance profiling: connect < 4 s, list < 500 ms.  
- [ ] T225 [Polish] Final QA review + governance sign-off.  
