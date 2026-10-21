@testable import Afterflow
import Foundation

enum CSVImportTestSupport {
    static let exportHeader =
        "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL"

    static let usLocale = Locale(identifier: "en_US")
    static let ukLocale = Locale(identifier: "en_GB")

    @MainActor static func service(locale: Locale = CSVImportTestSupport.usLocale) -> CSVImportService {
        CSVImportService(locale: locale)
    }

    /// The error a CSV string makes the importer throw, or nil when it imports.
    @MainActor static func thrownError(
        from csv: String,
        locale: Locale = CSVImportTestSupport.usLocale
    ) -> CSVImportService.CSVImportError? {
        do {
            _ = try self.service(locale: locale).importDetailed(from: csv)
            return nil
        } catch let error as CSVImportService.CSVImportError {
            return error
        } catch {
            return nil
        }
    }

    /// A date in the device's current time zone, matching how spreadsheet text without an offset is read.
    static func localDate(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        _ minute: Int = 0,
        _ second: Int = 0
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let components = DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }

    static func utcDate(_ iso8601: String) -> Date {
        ISO8601DateFormatter().date(from: iso8601) ?? Date(timeIntervalSince1970: 0)
    }

    /// Single-column-of-interest CSV: a Date column plus one extra column.
    static func csv(header: String, rows: [String]) -> String {
        ([header] + rows).joined(separator: "\n")
    }
}
