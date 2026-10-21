import Foundation
import SwiftData

struct CSVImportService {
    enum CSVImportError: Error, LocalizedError {
        case invalidHeader
        case invalidRow(Int)
        case parseFailure(String)
        case emptyFile
        case noValidRows

        var errorDescription: String? {
            switch self {
            case .invalidHeader:
                "CSV is missing the required \"Date\" column."
            case let .invalidRow(index):
                "Row \(index + 1) is invalid or incomplete."
            case let .parseFailure(reason):
                "Failed to parse CSV: \(reason)"
            case .emptyFile:
                "The CSV file is empty."
            case .noValidRows:
                "None of the rows could be imported. Each row needs a recognisable date and moods from 1 to 10."
            }
        }
    }

    /// Fixed reasons for skipped rows. They must never include cell contents.
    private enum SkipReason {
        static let date = "date not recognised"
        static let moodBefore = "mood before must be 1–10"
        static let moodAfter = "mood after must be 1–10"
    }

    /// Matches `TherapeuticSession`'s default mood.
    private static let defaultMoodBefore = 5

    private let dateParser: CSVImportDateParser

    /// - Parameter locale: decides whether ambiguous slash dates such as `03/04/2024` read day-first or month-first.
    init(locale: Locale = .current) {
        self.dateParser = CSVImportDateParser(locale: locale)
    }

    func `import`(from url: URL) throws -> [TherapeuticSession] {
        try self.importDetailed(from: url).sessions
    }

    func `import`(from data: Data) throws -> [TherapeuticSession] {
        try self.importDetailed(from: data).sessions
    }

    func `import`(from csvString: String) throws -> [TherapeuticSession] {
        try self.importDetailed(from: csvString).sessions
    }

    func importDetailed(from url: URL) throws -> CSVImportResult {
        let data = try Data(contentsOf: url)
        return try self.importDetailed(from: data)
    }

    func importDetailed(from data: Data) throws -> CSVImportResult {
        guard let csvString = CSVTextParser.decode(data) else {
            throw CSVImportError.parseFailure("File is not UTF-8, Windows-1252 or Mac Roman text.")
        }
        return try self.importDetailed(from: csvString)
    }

    /// Parses a spreadsheet export. Bad rows are skipped and reported in the result instead of aborting.
    /// Throws only for whole-file problems: an empty file, a missing Date column, or no importable rows.
    func importDetailed(from csvString: String) throws -> CSVImportResult {
        let text = CSVTextParser.normalizeLineEndings(CSVTextParser.stripByteOrderMark(from: csvString))
        let records = CSVTextParser.parse(text, delimiter: CSVTextParser.detectDelimiter(in: text))
        guard let headerIndex = records.firstIndex(where: { !CSVImportRow.isBlank($0) }) else {
            throw CSVImportError.emptyFile
        }

        let columns = CSVImportColumn.indexes(in: records[headerIndex])
        guard columns[.date] != nil else {
            throw CSVImportError.invalidHeader
        }

        var result = CSVImportResult()
        for index in (headerIndex + 1) ..< records.count where !CSVImportRow.isBlank(records[index]) {
            let row = CSVImportRow(fields: records[index], columns: columns)
            if let reason = self.appendSession(from: row, to: &result) {
                result.skippedRows.append(CSVImportSkippedRow(line: index + 1, reason: reason))
            }
        }

        if result.sessions.isEmpty, !result.skippedRows.isEmpty {
            throw CSVImportError.noValidRows
        }
        return result
    }

    /// Adds the row's session to `result`, or returns the reason it was skipped.
    /// Counters in `result` change only once the row is known to be importable.
    private func appendSession(from row: CSVImportRow, to result: inout CSVImportResult) -> String? {
        guard let date = self.dateParser.parse(row.text(.date)) else { return SkipReason.date }

        var defaultedMoodBefore = false
        let moodBefore: Int
        switch CSVImportValueMatcher.mood(from: row.text(.moodBefore)) {
        case .blank:
            moodBefore = Self.defaultMoodBefore
            defaultedMoodBefore = true
        case let .value(value):
            moodBefore = value
        case .invalid:
            return SkipReason.moodBefore
        }

        let moodAfter: Int?
        switch CSVImportValueMatcher.mood(from: row.text(.moodAfter)) {
        case .blank:
            moodAfter = nil
        case let .value(value):
            moodAfter = value
        case .invalid:
            return SkipReason.moodAfter
        }

        let labels = Self.resolveLabels(from: row, counting: &result)
        let session = TherapeuticSession(
            sessionDate: date,
            treatmentType: labels.treatment,
            administration: labels.administration,
            intention: row.text(.intention),
            moodBefore: moodBefore,
            moodAfter: moodAfter,
            reflections: labels.reflections
        )
        Self.applyMusicLink(row.trimmedText(.musicLink), to: session)

        if defaultedMoodBefore {
            result.defaultedMoodBeforeCount += 1
        }
        result.sessions.append(session)
        return nil
    }

    private struct ResolvedLabels {
        let treatment: PsychedelicTreatmentType
        let administration: AdministrationMethod
        let reflections: String
    }

    /// Maps treatment and administration text to enums. A blank cell is `.other`; text we cannot map is also
    /// `.other`, but the original is kept in the reflections and counted so nothing is silently lost.
    private static func resolveLabels(
        from row: CSVImportRow,
        counting result: inout CSVImportResult
    ) -> ResolvedLabels {
        let treatmentText = row.trimmedText(.treatment)
        let treatment = CSVImportValueMatcher.treatment(for: treatmentText)
        let administrationText = row.trimmedText(.administration)
        let administration = CSVImportValueMatcher.administration(for: administrationText)

        var reflections = row.text(.reflections)
        if treatment == nil, !treatmentText.isEmpty {
            reflections = Self.appendingNote("Imported treatment: \(treatmentText)", to: reflections)
            result.unrecognisedTreatmentCount += 1
        }
        if administration == nil, !administrationText.isEmpty {
            reflections = Self.appendingNote("Imported administration: \(administrationText)", to: reflections)
            result.unrecognisedAdministrationCount += 1
        }
        return ResolvedLabels(
            treatment: treatment ?? .other,
            administration: administration ?? .other,
            reflections: reflections
        )
    }

    private static func appendingNote(_ note: String, to text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? note : text + "\n\n" + note
    }

    private static func applyMusicLink(_ musicLink: String, to session: TherapeuticSession) {
        guard !musicLink.isEmpty else { return }
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
        if host.hasPrefix("www.") {
            host.removeFirst(4)
        }

        if host
            .contains("podcasts.apple.com") || (host.contains("itunes.apple.com") && url.path.contains("/podcast/")) {
            return .applePodcasts
        }
        if host.contains("spotify.com") {
            return .spotify
        }
        if host.contains("youtube.com") || host == "youtu.be" || host
            .contains("youtube-nocookie.com") {
            return .youtube
        }
        if host.contains("soundcloud.com") {
            return .soundcloud
        }
        if host.contains("music.apple.com") || host.contains("itunes.apple.com") {
            return .appleMusic
        }
        if host.contains("tidal.com") {
            return .tidal
        }
        if host.contains("bandcamp.com") {
            return .bandcamp
        }
        return .linkOnly
    }
}
