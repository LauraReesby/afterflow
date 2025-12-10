import Foundation
import SwiftData

// swiftlint:disable file_length

struct CSVImportService: Sendable {
    enum CSVImportError: Error, LocalizedError {
        case invalidHeader
        case invalidRow(Int)
        case parseFailure(String)

        var errorDescription: String? {
            switch self {
            case .invalidHeader:
                "CSV header does not match expected export format."
            case let .invalidRow(index):
                "Row \(index + 1) is invalid or incomplete."
            case let .parseFailure(reason):
                "Failed to parse CSV: \(reason)"
            }
        }
    }

    // swiftlint:disable function_body_length
    func `import`(from url: URL) throws -> [TherapeuticSession] {
        let data = try Data(contentsOf: url)
        return try self.import(from: data)
    }

    func `import`(from data: Data) throws -> [TherapeuticSession] {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw CSVImportError.parseFailure("Data is not UTF-8 encoded.")
        }
        return try self.import(from: csvString)
    }

    func `import`(from csvString: String) throws -> [TherapeuticSession] {
        let rows = try Self.parseCSV(csvString)
        guard let header = rows.first else { return [] }
        guard header.map(Self.trimmedHeader) == Self.expectedHeader else {
            throw CSVImportError.invalidHeader
        }

        let payloadRows = rows.dropFirst()
        var sessions: [TherapeuticSession] = []

        for (index, fields) in payloadRows.enumerated() {
            guard fields.count == Self.expectedHeader.count else {
                throw CSVImportError.invalidRow(index + 1)
            }

            let dateString = fields[0]
            let treatmentString = fields[1]
            let administrationString = fields[2]
            let intention = fields[3]
            let moodBeforeString = fields[4]
            let moodAfterString = fields[5]
            let reflections = fields[6]
            let musicLink = fields[7]

            guard let date = Self.dateFormatter.date(from: dateString) else {
                throw CSVImportError.invalidRow(index + 1)
            }

            guard let treatment = PsychedelicTreatmentType.allCases.first(where: { $0.displayName == treatmentString })
            else {
                throw CSVImportError.invalidRow(index + 1)
            }

            guard let administration = AdministrationMethod.allCases
                .first(where: { $0.displayName == administrationString }) else {
                throw CSVImportError.invalidRow(index + 1)
            }

            guard let moodBefore = Int(moodBeforeString), let moodAfter = Int(moodAfterString) else {
                throw CSVImportError.invalidRow(index + 1)
            }

            let session = TherapeuticSession(
                sessionDate: date,
                treatmentType: treatment,
                administration: administration,
                intention: intention,
                moodBefore: moodBefore,
                moodAfter: moodAfter,
                reflections: reflections
            )

            if !musicLink.isEmpty {
                let sanitizedLink = Self.stripInjectionGuard(musicLink)
                if let classification = Self.classifyLink(sanitizedLink) {
                    session.musicLinkURL = classification.originalURL.absoluteString
                    session.musicLinkWebURL = classification.canonicalURL.absoluteString
                    session.musicLinkProvider = classification.provider
                } else {
                    session.musicLinkURL = sanitizedLink
                    session.musicLinkWebURL = sanitizedLink
                    session.musicLinkProvider = .unknown
                }
            }

            sessions.append(session)
        }

        return sessions
    }

    // swiftlint:enable function_body_length

    private static func parseCSV(_ csv: String) throws -> [[String]] {
        let normalized = csv.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var insideQuotes = false

        let scalars = Array(normalized)
        var index = 0
        while index < scalars.count {
            let char = scalars[index]
            if char == "\"" {
                if insideQuotes, index + 1 < scalars.count, scalars[index + 1] == "\"" {
                    field.append("\"")
                    index += 2
                    continue
                }
                insideQuotes.toggle()
                index += 1
                continue
            }

            if char == ",", !insideQuotes {
                row.append(field)
                field = ""
                index += 1
                continue
            }

            if char == "\n", !insideQuotes {
                row.append(field)
                rows.append(row)
                row = []
                field = ""
                index += 1
                continue
            }

            field.append(char)
            index += 1
        }

        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }

        return rows
    }

    private static func stripInjectionGuard(_ value: String) -> String {
        guard let first = value.first, first == "'" else { return value }
        return String(value.dropFirst())
    }

    private struct LinkClassification {
        let provider: MusicLinkProvider
        let originalURL: URL
        let canonicalURL: URL
    }

    private static func classifyLink(_ urlString: String) -> LinkClassification? {
        guard let original = normalize(urlString: urlString) else { return nil }
        let provider = Self.provider(for: original)
        let canonical = provider.fallbackWebURL(for: original) ?? original
        return LinkClassification(provider: provider, originalURL: original, canonicalURL: canonical)
    }

    private static func normalize(urlString: String) -> URL? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.lowercased().hasPrefix("spotify:") {
            return URL(string: trimmed)
        }
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return URL(string: trimmed)
        }
        if trimmed.hasPrefix("//") {
            return URL(string: "https:\(trimmed)")
        }
        return URL(string: "https://\(trimmed)")
    }

    private static func provider(for url: URL) -> MusicLinkProvider {
        if let scheme = url.scheme?.lowercased(), scheme == "spotify" {
            return .spotify
        }
        guard var host = url.host?.lowercased() else { return .linkOnly }
        if host.hasPrefix("www.") { host.removeFirst(4) }

        if host
            .contains("podcasts.apple.com") || (host.contains("itunes.apple.com") && url.path.contains("/podcast/")) {
            return .applePodcasts
        }
        if host.contains("spotify.com") { return .spotify }
        if host.contains("youtube.com") || host == "youtu.be" || host
            .contains("youtube-nocookie.com") { return .youtube }
        if host.contains("soundcloud.com") { return .soundcloud }
        if host.contains("music.apple.com") || host.contains("itunes.apple.com") { return .appleMusic }
        if host.contains("tidal.com") { return .tidal }
        if host.contains("bandcamp.com") { return .bandcamp }
        return .linkOnly
    }

    private nonisolated static func trimmedHeader(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let expectedHeader: [String] = [
        "Date",
        "Treatment Type",
        "Administration",
        "Intention",
        "Mood Before",
        "Mood After",
        "Reflections",
        "Music Link URL"
    ]

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
