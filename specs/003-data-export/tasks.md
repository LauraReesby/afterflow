# Task List — Data Export (v2)

## Phase 1 – CSV Export
- [ ] T301 [US1] Define CSV schema and mapping from TherapySession.  
- [ ] T302 [US1] Implement CSVExportService with RFC‑4180 quoting + UTF‑8.  
- [ ] T303 [US1] Inject CSV injection protection for leading formula chars.  
- [ ] T304 [US1] Add date range + treatment type filters.  
- [ ] T305 [US1] Unit tests: mapping, quoting, filters, 1k dataset perf.  
- [ ] T306 [US1] Constitutional QA verification: accessibility, performance profiling, privacy compliance.

## Phase 2 – PDF Export
- [ ] T307 [US2] Implement PDFExportService with selectable text + pagination.  
- [ ] T308 [US2] Build cover page with neutral privacy note (optional).  
- [ ] T309 [US2] Render session summaries with headings + sections.  
- [ ] T310 [US2] Performance test: 25 sessions < 4 s.  
- [ ] T311 [US2] Constitutional QA verification: accessibility, performance profiling, privacy compliance.

## Phase 3 – Export UX & Flow
- [ ] T312 [US3] ExportSheetView for filters + format selection.  
- [ ] T313 [US3] ExportProgressView with cancel + completion toast.  
- [ ] T314 [US3] FileExporter integration (share sheet / Files).  
- [ ] T315 [US3] Temp file cleanup strategy on success/cancel/error.  
- [ ] T316 [US3] Accessibility labels; VoiceOver reads progress.  
- [ ] T317 [US3] Constitutional QA verification: accessibility, performance profiling, privacy compliance.

## Phase 4 – Polish & Governance
- [ ] T318 [Polish] Localized PDF headings; locale‑aware formatting.  
- [ ] T319 [Polish] Add tests for long text and emoji in CSV/PDF.  
- [ ] T320 [Polish] Final privacy review: no network usage; neutral filenames.  
- [ ] T321 [Polish] Final QA review + governance sign‑off.
