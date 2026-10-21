import Foundation

/// Parses the date formats spreadsheets commonly produce. Formats are tried in a fixed order:
/// the Afterflow export format, ISO 8601 with a time zone, local ISO-like forms, slash dates, then month names.
struct CSVImportDateParser {
    /// Slash formatters in the order they are tried; the locale decides whether day or month comes first.
    private let slashFormatters: [DateFormatter]

    init(locale: Locale = .current) {
        if Self.prefersDayFirst(locale) {
            self.slashFormatters = Self.dayFirstSlashFormatters + Self.monthFirstSlashFormatters
        } else {
            self.slashFormatters = Self.monthFirstSlashFormatters + Self.dayFirstSlashFormatters
        }
    }

    func parse(_ rawValue: String) -> Date? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let exact = Self.exportFormatter.date(from: trimmed) {
            return exact
        }

        let text = Self.normalizedText(trimmed)
        if let date = Self.exportFormatter.date(from: text) ?? Self.parseISO8601(text) {
            return date
        }
        return Self.firstPlausibleDate(in: Self.localISOFormatters, text)
            ?? Self.firstPlausibleDate(in: self.slashFormatters, text)
            ?? Self.firstPlausibleDate(in: Self.monthNameFormatters, text)
    }

    // MARK: - Locale

    /// True when the locale's short date pattern puts the day before the month (for example `dd/MM/y`).
    private static func prefersDayFirst(_ locale: Locale) -> Bool {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        let pattern = formatter.dateFormat ?? ""

        guard let dayIndex = pattern.firstIndex(of: "d"),
              let monthIndex = pattern.firstIndex(where: { $0 == "M" || $0 == "L" })
        else { return false }
        return dayIndex < monthIndex
    }

    // MARK: - Helpers

    /// Excel and newer system libraries emit narrow or non-breaking spaces before AM/PM; the patterns expect a
    /// plain space and upper-case day periods.
    private static func normalizedText(_ value: String) -> String {
        var text = value
            .replacingOccurrences(of: "\u{202F}", with: " ")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
        let upper = text.uppercased()
        if upper.hasSuffix("AM") || upper.hasSuffix("PM") {
            text = String(text.dropLast(2)) + String(upper.suffix(2))
        }
        return text
    }

    /// `DateFormatter` may accept a prefix of the string and ignore the rest, so two guards keep it honest:
    /// - a pattern without a time of day is skipped when the text contains one (the time would be silently lost);
    /// - a two-digit year read by a four-digit pattern parses literally (year 24, not 2024), so results before
    ///   `earliestPlausibleDate` are rejected and the next pattern gets a turn.
    private static func firstPlausibleDate(in formatters: [DateFormatter], _ text: String) -> Date? {
        let textHasTime = text.contains(":")
        for formatter in formatters {
            if textHasTime, !(formatter.dateFormat ?? "").contains(":") {
                continue
            }
            if let date = formatter.date(from: text), date >= Self.earliestPlausibleDate {
                return date
            }
        }
        return nil
    }

    private static func parseISO8601(_ text: String) -> Date? {
        for formatter in Self.iso8601Formatters {
            if let date = formatter.date(from: text) {
                return date
            }
        }
        return nil
    }

    private static func makeFormatter(_ pattern: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = pattern
        return formatter
    }

    /// One formatter per date pattern and time suffix, most specific (time with seconds) first and the bare date
    /// last, so a pattern never swallows the front of a longer value.
    private static func makeFormatters(datePatterns: [String]) -> [DateFormatter] {
        let timeSuffixes = [" h:mm:ss a", " h:mm a", " H:mm:ss", " H:mm", ""]
        var formatters: [DateFormatter] = []
        for datePattern in datePatterns {
            for suffix in timeSuffixes {
                formatters.append(CSVImportDateParser.makeFormatter(datePattern + suffix))
            }
        }
        return formatters
    }

    // MARK: - Cached formatters

    /// 1900-01-01 UTC.
    private static let earliestPlausibleDate = Date(timeIntervalSince1970: -2_208_988_800)

    /// Must stay identical to `CSVExportService`'s formatter so exports round-trip exactly.
    private static let exportFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// ISO 8601 with an explicit offset or `Z`, with and without fractional seconds.
    private static let iso8601Formatters: [ISO8601DateFormatter] = {
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return [plain, fractional]
    }()

    /// ISO-like dates without a time zone are read as local time, which is what a spreadsheet cell means.
    /// The 12-hour patterns come before `HH:mm` so a trailing `PM` is never dropped.
    private static let localISOFormatters: [DateFormatter] = [
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm",
        "yyyy-MM-dd h:mm:ss a",
        "yyyy-MM-dd h:mm a",
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd HH:mm",
        "yyyy-MM-dd"
    ].map { CSVImportDateParser.makeFormatter($0) }

    private static let monthFirstSlashFormatters = CSVImportDateParser
        .makeFormatters(datePatterns: ["M/d/yyyy", "M/d/yy"])

    private static let dayFirstSlashFormatters = CSVImportDateParser
        .makeFormatters(datePatterns: ["d/M/yyyy", "d/M/yy"])

    private static let monthNameFormatters = CSVImportDateParser
        .makeFormatters(datePatterns: ["d MMM yyyy", "MMM d, yyyy", "MMMM d, yyyy", "d MMMM yyyy"])
}
