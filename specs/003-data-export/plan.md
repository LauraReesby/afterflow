# Implementation Plan — Data Export (v2)

## Overview
Deliver offline CSV and PDF export for TherapeuticSession entries with filtering and secure local handling.

## Technical Context
**Language/Version:** Swift 5.9+ / iOS ≥ 17.6 (tested on 17.6+)  
**Frameworks:** SwiftUI, Foundation, PDFKit (or SwiftUI + UIGraphics PDF renderer), UniformTypeIdentifiers  
**Storage:** Local temp directory for export; no remote storage  
**Testing:** TDD (Red-Green-Refactor) + XCTest (unit/perf) + XCUITest (UI) + Accessibility tests  
**Performance Goals:** CSV(1k) < 2s; PDF(25 sessions) < 4s; I/O < 16ms main thread  
**Privacy:** No analytics; exports remain local until user shares/saves.

## Architecture
```
Services/
 ├── CSVExportService.swift
 ├── PDFExportService.swift
 └── ExportCoordinator.swift        # Orchestrates filters, progress, cancel
ViewModels/
 └── ExportViewModel.swift
Views/
 ├── ExportSheetView.swift          # Filters + format selector
 └── ExportProgressView.swift       # Progress + cancel
Tests/
 ├── CSVExportTests/
 ├── PDFExportTests/
 ├── ExportFlowUITests/
 └── PerformanceTests/
```

## File Naming
`Afterflow-Export-YYYYMMDD-HHmm[-RANGE][-TYPE].ext`  
Examples:  
- `Afterflow-Export-20251106-1921-ALL-csv.csv`  
- `Afterflow-Export-20251106-1921-2025Q4-PDF.pdf`

## Filters
- Date range (start/end)  
- Treatment type (multi‑select)  
- Limit sessions (optional cap for PDF packets)

## Metrics
- Export success rate in tests ≥ 99%.  
- Measured durations within targets.  
- Zero network calls in export flows.

