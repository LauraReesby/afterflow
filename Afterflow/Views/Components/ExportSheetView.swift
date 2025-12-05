import SwiftUI
import UniformTypeIdentifiers

struct ExportSheetView: View {
    let availableTreatmentTypes: [PsychedelicTreatmentType]
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
            .navigationTitle("Export Sessions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: self.onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Export") {
                        let range: ClosedRange<Date>? = self.useDateFilter ? self.startDate ... self.endDate : nil
                        let request = ExportRequest(
                            format: self.selectedFormat,
                            dateRange: range,
                            treatmentType: self.selectedTreatment
                        )
                        self.onExport(request)
                    }
                }
            }
        }
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

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .csv: "CSV"
        case .pdf: "PDF"
        }
    }
}

struct BinaryFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText, .pdf] }
    static var writableContentTypes: [UTType] { [.commaSeparatedText, .pdf] }

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
