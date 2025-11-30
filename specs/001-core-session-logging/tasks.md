# Task List — Core Session Logging (v2)

## Phase 1 – Model & Persistence
- [x] T001 [US1] Define TherapeuticSession entity fields per spec.  
- [x] T002 [US1] Implement SwiftData persistence and auto-save service.  
- [x] T003 [US1] Unit tests for TherapeuticSession CRUD and auto-save recovery.  
- [x] T004 [US1] Verify constitutional quality gates: 80% coverage, 100% public API coverage, TDD compliance.  

## Phase 2 – Session Form
- [x] T005 [US1] Build SessionFormView with date, type, intentions.  
- [x] T006 [US1] Validation + inline errors.  
- [x] T007 [US1] Keyboard navigation and dismiss behavior.  
- [x] T008 [US1] Date validation and normalization.  
- [x] T009 [US1] UI tests for form validation and keyboard flow.  
- [x] T010 [US1] Constitutional QA verification: accessibility, performance profiling, privacy compliance.  
- [x] T010a [US1] Implement Draft vs. Needs Reflection field grouping + inline status indicator.  
- [x] T010b [US1] ViewModel-only draft persistence + unit tests ensuring SwiftData writes occur after before-mood/intention complete.  

## Phase 3 – (Removed)  
- [x] T011 [US2] Retired in favor of Feature 002 playlist links; environment field removed.  
- [x] T012 [US2] (N/A)  
- [x] T013 [US2] (N/A)  
- [x] T014 [US2] (N/A)  
- [x] T015 [US2] (N/A)  

## Phase 4 – Mood Ratings
- [x] T016 [US3] Add before/after mood fields.  
- [x] T017 [US3] MoodRatingView (slider + emoji map).  
- [x] T018 [US3] VoiceOver focus + value announcement tests.  
- [x] T019 [US3] Dynamic Type XL+ snapshot tests.  
- [x] T020 [US3] Constitutional QA verification: accessibility, performance profiling, privacy compliance.  

## Phase 5 – Reflections
- [x] T021 [US4] Add reflections field to model.  
- [x] T022 [US4] SessionDetailView (editable reflection).  
- [x] T023 [US4] Empty-state helper copy.  
- [x] T024 [US4] Persistence error handling.  
- [x] T025 [US4] Constitutional QA verification: accessibility, performance profiling, privacy compliance.  
- [x] T025a [US4] Implement session status pipeline (Draft ➜ Needs Reflection ➜ Complete) with reminder scheduling.  
- [x] T025b [US4] Local notification handling + auto-save once Needs Reflection is active.  

## Phase 6 – History List
- [x] T026 [US5] SessionListView with SwiftData query.  
- [x] T027 [US5] SessionListViewModel (filter/sort).  
- [x] T028 [US5] Delete + Undo flow.  
- [x] T029 [US5] Large dataset fixture + perf tests.  
- [x] T030 [US5] Constitutional QA verification: accessibility, performance profiling, privacy compliance.  
- [x] T030a [US5] Surface Needs Reflection badge + reminder metadata in list/detail + UI tests.  

## Phase 7 – Polish & Cross-Cutting
- [ ] T031 [Polish] Add accessibility labels + VoiceOver tests.  
- [ ] T032 [Polish] Performance optimization for large lists.  
- [ ] T033 [Polish] Haptic feedback for key interactions.  
- [ ] T034 [Polish] Migration Notes documentation.  
- [ ] T035 [Polish] App Privacy manifest = Data Not Collected.  
- [ ] T036 [Polish] Final QA review + governance sign-off.  
- [ ] T037 [Polish] Reminder lifecycle QA (unit + UI tests) covering scheduling, cancelation, completion flows.  
