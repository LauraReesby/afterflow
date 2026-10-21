import SwiftUI
import UniformTypeIdentifiers

struct ExportSheetView: View {
    let availableTreatmentTypes: [PsychedelicTreatmentType]
    var lastBackupDate: Date?
    let onCancel: () -> Void
    let onExport: (ExportRequest) -> Void

    @State private var selectedFormat: ExportFormat = .csv
    @State private var useDateFilter = false
    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var endDate: Date = .init()
    @State private var selectedTreatment: PsychedelicTreatmentType?

    var body: some View {
        NavigationStack {
            Form {
                Section("Format") {
                    Picker("Format", selection: self.$selectedFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("exportFormatPicker")
                }

                if self.selectedFormat == .backup {
                    self.backupSection
                } else {
                    self.filtersSection
                }
            }
            .navigationTitle("Export Sessions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: self.onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Export") {
                        self.onExport(self.makeRequest())
                    }
                }
            }
        }
    }

    private var filtersSection: some View {
        Section("Filters") {
            Toggle("Filter by date", isOn: self.$useDateFilter)
                .accessibilityIdentifier("exportDateToggle")
            if self.useDateFilter {
                DatePicker("Start", selection: self.$startDate, displayedComponents: [.date])
                    .accessibilityIdentifier("exportStartDate")
                DatePicker("End", selection: self.$endDate, displayedComponents: [.date])
                    .accessibilityIdentifier("exportEndDate")
            }

            Picker("Treatment", selection: self.$selectedTreatment) {
                Text("All Treatments").tag(PsychedelicTreatmentType?.none)
                ForEach(self.availableTreatmentTypes, id: \.self) { type in
                    Text(type.displayName).tag(PsychedelicTreatmentType?.some(type))
                }
            }
            .accessibilityIdentifier("exportTreatmentPicker")
        }
    }

    private var backupSection: some View {
        Section("About backups") {
            Text(
                "Includes every session and all its details, so you can restore it later or move to a new device. "
                    + "The file isn't encrypted; keep it somewhere private."
            )
            .accessibilityIdentifier("backupDescription")
            Label(BackupService.lastBackupText(for: self.lastBackupDate), systemImage: "clock")
                .accessibilityIdentifier("lastBackupStatus")
        }
    }

    /// Filters apply only to reports; a backup always covers every session.
    private func makeRequest() -> ExportRequest {
        guard self.selectedFormat != .backup else {
            return ExportRequest(format: .backup, dateRange: nil, treatmentType: nil)
        }
        let range: ClosedRange<Date>? = self.useDateFilter ? self.startDate ... self.endDate : nil
        return ExportRequest(format: self.selectedFormat, dateRange: range, treatmentType: self.selectedTreatment)
    }
}

struct ExportRequest {
    let format: ExportFormat
    let dateRange: ClosedRange<Date>?
    let treatmentType: PsychedelicTreatmentType?
}

enum ExportFormat: String, CaseIterable, Identifiable {
    case csv
    case pdf
    case backup

    var id: String {
        self.rawValue
    }

    var displayName: String {
        switch self {
        case .csv: "CSV"
        case .pdf: "PDF"
        case .backup: "Backup"
        }
    }
}

struct BinaryFileDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.commaSeparatedText, .pdf, .json]
    }

    static var writableContentTypes: [UTType] {
        [.commaSeparatedText, .pdf, .json]
    }

    let data: Data
    let contentType: UTType

    init(data: Data, contentType: UTType) {
        self.data = data
        self.contentType = contentType
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
        self.contentType = configuration.contentType
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: self.data)
    }
}
