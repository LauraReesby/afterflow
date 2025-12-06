# Feature Spec — Data Export (v2)
**Feature ID:** 003  
**Status:** Completed  
**Depends On:** Core Session Logging (001)  
**Constitution Reference:** v1.0.0  
**Owner:** Engineering + Product

## Intent
Allow users to export their session data for personal reflection or to share summaries with a clinician, while preserving privacy and staying fully under the user's control.

## Problem
Users need a simple way to take their data with them (for backups, analysis, or therapy sessions) without vendor lock‑in or cloud dependencies.

## Success Criteria
- Export selected sessions to **CSV** (structured) and **PDF** (readable summary).  
- Export runs **offline**, locally, and respects user filters (date range, treatment type).  
- File names are human‑readable and time‑stamped.  
- Exports use neutral, non‑clinical language and avoid medical claims.  
- **Performance**: CSV export 100 sessions < 5s; PDF generation 25 sessions < 8s; UI responsive throughout.
- QA standards met per Constitution § Quality Gates.

---

## User Stories
### US1 — CSV Export
**As a user**, I want to export my sessions to CSV so I can analyze or archive them.  
**Acceptance**
1. I can choose **All** or apply **filters** (date range, treatment type).  
2. CSV columns match a documented schema (see TR‑302).  
3. Export is local and uses the iOS share sheet / Files picker.  
4. Special characters and newlines are safely quoted; commas are preserved.

### US2 — PDF Summary
**As a user**, I want a readable PDF summary per session (or a multi‑session packet) to share with my clinician/coach.  
**Acceptance**
1. Neutral headings and reflective tone (no diagnoses).  
2. Includes intentions, playlist link title (if present), moods, reflections, and date/time.  
3. Optional cover page with total sessions included.  
4. Pagination, selectable text, and legible in light/dark print.

### US3 — Export Management
**As a user**, I want predictable file names and control over what gets exported and where it is saved.  
**Acceptance**
1. Filenames use a consistent convention: `Afterflow-Export-YYYYMMDD-HHmm` with suffix `-csv` or `-pdf`.  
2. Progress indicator and completion toast.  
3. Exports clean up temporary files.  
4. Large datasets (≥ 1k sessions) complete without UI jank.

---

## Functional Requirements
| ID | Requirement |
|----|-------------|
| FR-301 | Export filtered sessions to CSV using documented schema. |
| FR-302 | Generate PDF summaries (single or multi‑session). |
| FR-303 | Use iOS file exporter / share sheet; never auto‑upload. |
| FR-304 | Provide date range + treatment type filters. |
| FR-305 | Show progress; handle cancellation gracefully. |
| FR-306 | Sanitize content to prevent CSV injection and ensure quoting. |
| FR-307 | Clean up temporary files after completion/cancel. |
| FR-308 | All exports are local/offline; no analytics. |

---

## Technical Requirements
| ID | Description |
|----|-------------|
| TR-301 | SwiftUI 5.9 views on iOS ≥ 17.6 for export functionality: date filters, format choice, progress display. |
| TR-302 | Core Data integration per shared `TherapeuticSession` model from Feature 001. |
| TR-303 | CSV generation uses RFC 4180 conventions: comma delimiter, CRLF line endings, double‑quote escaping, UTF‑8 with BOM optional user toggle. |
| TR-304 | Prevent CSV injection: prefix cells starting with `=`, `+`, `-`, `@` with an apostrophe `'`. |
| TR-305 | PDF renderer with selectable text; A4/Letter support; auto pagination; margins ≥ 12pt; font scaling with Dynamic Type; optional cover page. |
| TR-306 | Performance: CSV 1k sessions in < 2 s on target device; PDF 25 sessions in < 4 s. |
| TR-307 | No network usage; works in airplane mode. |
| TR-308 | Respect locale for display in PDF; use ISO‑8601 in CSV. |
| TR-309 | File naming convention `Afterflow-Export-YYYYMMDD-HHmm[-RANGE][-TYPE].ext`. |
| TR-310 | Performance: launch < 2s; I/O < 16ms main thread (constitutional requirements). |

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
- **Export-Specific**: CSV quoting/escaping accuracy, schema mapping verification, filter application testing.
- **File Integrity**: Generated file format compliance, no data corruption testing.

---

## Risks & Mitigation
| Risk | Mitigation |
|------|------------|
| CSV parsing issues in spreadsheets | RFC‑4180 quoting; UTF‑8 BOM toggle. |
| Large PDF memory usage | Stream rendering; paginate; limit image sizes. |
| Privacy leakage via filenames | Neutral names; no user identifiers.

---

## Dependencies
- Core Session Logging (001)

---

## Amendment Notes
Feature changes require Constitution review and governance approval.  
- Implementation delivered via `CSVExportService` and `PDFExportService` with on-device processing, RFC‑4180 quoting and file naming `Afterflow-Export-YYYYMMDD-HHmm`.  
- Privacy note removed from cover page per governance review; cover page remains optional.
