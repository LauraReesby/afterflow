import Foundation

/// Exports TherapeuticSession data to CSV with safe defaults (RFC 4180 quoting, UTF-8, and CSV injection guard).
struct CSVExportService {
    /// Export the provided sessions to a CSV file at a temporary URL.
    /// - Parameters:
    ///   - sessions: Sessions to export.
    ///   - dateRange: Optional date filter; only sessions whose `sessionDate` falls inside are included.
    ///   - treatmentType: Optional treatment filter.
    /// - Returns: File URL pointing to the generated CSV in a temporary directory.
    @MainActor func export(
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

    // MARK: - Helpers

    private static func escape(_ value: String) -> String {
        // Guard against formula injection by prefixing values starting with =,+,-,@ with a single quote.
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

    enum CSVExportError: Error {
        case encodingFailed
    }
}
