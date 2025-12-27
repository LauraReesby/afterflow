import Foundation

struct CSVExportService: Sendable {
    func export(
        sessions: [TherapeuticSession],
        dateRange: ClosedRange<Date>? = nil,
        treatmentType: PsychedelicTreatmentType? = nil
    ) throws -> URL {
        let filtered = sessions.filter { session in
            if let range = dateRange, !range.contains(session.sessionDate) { return false }
            if let type = treatmentType, session.treatmentType != type { return false }
            return true
        }

        let rows: [[String]] = filtered.map { session in
            [
                Self.dateFormatter.string(from: session.sessionDate),
                session.treatmentType.displayName,
                session.administration.displayName,
                session.intention,
                String(session.moodBefore),
                String(session.moodAfter),
                session.reflections,
                session.musicLinkURL ?? session.musicLinkWebURL ?? ""
            ].map(Self.escape)
        }

        let header = [
            "Date",
            "Treatment Type",
            "Administration",
            "Intention",
            "Mood Before",
            "Mood After",
            "Reflections",
            "Music Link URL"
        ].map(Self.escape)

        let csvLines = ([header] + rows).map { $0.joined(separator: ",") }
        let csvString = csvLines.joined(separator: "\n")

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Afterflow-Export-\(UUID().uuidString).csv")

        try csvString.data(using: .utf8)?.write(to: fileURL, options: .atomic)
            ?? { throw CSVExportError.encodingFailed }()

        return fileURL
    }

    private nonisolated static func escape(_ value: String) -> String {
        let injectionGuarded: String = if let first = value.first, ["=", "+", "-", "@"].contains(first) {
            "'" + value
        } else {
            value
        }

        var needsQuotes = false
        var escaped = ""
        for char in injectionGuarded {
            if char == "\"" {
                escaped.append("\"")
                escaped.append(char)
                needsQuotes = true
            } else {
                escaped.append(char)
                if char == "," || char == "\n" || char == "\r" {
                    needsQuotes = true
                }
            }
        }

        if needsQuotes || escaped.isEmpty {
            return "\"" + escaped + "\""
        }
        return escaped
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    func exportExampleImport() throws -> URL {
        let sessions = Self.exampleImportSessions()
        return try self.export(sessions: sessions)
    }

    private static func exampleImportSessions() -> [TherapeuticSession] {
        let treatments = PsychedelicTreatmentType.allCases
        let administrations: [AdministrationMethod] = [.intravenous, .intramuscular, .oral, .nasal, .other]
        var sessions: [TherapeuticSession] = []
        let now = Date()

        for (index, treatment) in treatments.enumerated() {
            let admin = administrations[index % administrations.count]
            let session = TherapeuticSession(
                sessionDate: now.addingTimeInterval(TimeInterval(-index * 86400)),
                treatmentType: treatment,
                administration: admin,
                intention: "Example \(treatment.displayName)",
                moodBefore: 5,
                moodAfter: 6,
                reflections: "Example reflection for \(treatment.displayName)"
            )
            sessions.append(session)
        }

        return sessions
    }

    enum CSVExportError: Error {
        case encodingFailed
    }
}
