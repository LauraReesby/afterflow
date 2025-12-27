@testable import Afterflow
import Foundation

/// Factory for creating standardized error scenarios for testing
enum ErrorFixtureFactory {
    // MARK: - CSV Import Errors

    /// Invalid CSV header error
    static func makeInvalidHeaderError() -> CSVImportService.CSVImportError {
        .invalidHeader
    }

    /// Invalid CSV row error
    static func makeInvalidRowError(row: Int = 1) -> CSVImportService.CSVImportError {
        .invalidRow(row)
    }

    /// Parse failure error
    static func makeParseFailureError(reason: String = "Parse failed") -> CSVImportService.CSVImportError {
        .parseFailure(reason)
    }

    // MARK: - File System Errors

    /// File not found error
    static func makeFileNotFoundError(path: String = "/tmp/nonexistent.csv") -> NSError {
        NSError(
            domain: NSCocoaErrorDomain,
            code: NSFileReadNoSuchFileError,
            userInfo: [
                NSFilePathErrorKey: path,
                NSLocalizedDescriptionKey: "The file \"\(path)\" couldn't be opened because there is no such file."
            ]
        )
    }

    /// Permission denied error
    static func makePermissionDeniedError(path: String = "/tmp/protected.csv") -> NSError {
        NSError(
            domain: NSCocoaErrorDomain,
            code: NSFileReadNoPermissionError,
            userInfo: [
                NSFilePathErrorKey: path,
                NSLocalizedDescriptionKey: "The file \"\(path)\" couldn't be opened because you don't have permission to view it."
            ]
        )
    }

    /// Disk full error
    static func makeDiskFullError() -> NSError {
        NSError(
            domain: NSCocoaErrorDomain,
            code: NSFileWriteOutOfSpaceError,
            userInfo: [
                NSLocalizedDescriptionKey: "The operation couldn't be completed because the disk is full."
            ]
        )
    }

    // MARK: - Network Errors

    /// Network timeout error
    static func makeTimeoutError() -> NSError {
        NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorTimedOut,
            userInfo: [
                NSLocalizedDescriptionKey: "The request timed out."
            ]
        )
    }

    /// No internet connection error
    static func makeNoConnectionError() -> NSError {
        NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [
                NSLocalizedDescriptionKey: "The Internet connection appears to be offline."
            ]
        )
    }

    // MARK: - Export Errors

    /// Export failure error
    static func makeExportFailureError(reason: String = "Unknown export error") -> NSError {
        NSError(
            domain: "com.afterflow.export",
            code: 1000,
            userInfo: [
                NSLocalizedDescriptionKey: "Export failed: \(reason)"
            ]
        )
    }

    /// Invalid export format error
    static func makeInvalidFormatError(format: String = "unknown") -> NSError {
        NSError(
            domain: "com.afterflow.export",
            code: 1001,
            userInfo: [
                NSLocalizedDescriptionKey: "Invalid export format: \(format)"
            ]
        )
    }

    // MARK: - Import Errors

    /// Import parsing error
    static func makeParseError(line: Int = 1, column: Int = 1) -> NSError {
        NSError(
            domain: "com.afterflow.import",
            code: 2000,
            userInfo: [
                NSLocalizedDescriptionKey: "Parse error at line \(line), column \(column)"
            ]
        )
    }

    /// Invalid data encoding error
    static func makeEncodingError(encoding: String = "UTF-8") -> NSError {
        NSError(
            domain: NSCocoaErrorDomain,
            code: NSFileReadInapplicableStringEncodingError,
            userInfo: [
                NSLocalizedDescriptionKey: "The data couldn't be read because it isn't in the correct format (\(encoding))."
            ]
        )
    }

    // MARK: - Security-Scoped Resource Errors

    /// Security-scoped resource access denied error
    static func makeSecurityScopedResourceError() -> NSError {
        NSError(
            domain: NSCocoaErrorDomain,
            code: NSFileReadNoPermissionError,
            userInfo: [
                NSLocalizedDescriptionKey: "The app doesn't have permission to access this file."
            ]
        )
    }

    // MARK: - iCloud Errors

    /// iCloud download failure error
    static func makeICloudDownloadError() -> NSError {
        NSError(
            domain: NSCocoaErrorDomain,
            code: NSFileReadUnknownError,
            userInfo: [
                NSLocalizedDescriptionKey: "The file is not currently available from iCloud."
            ]
        )
    }

    /// iCloud not available error
    static func makeICloudUnavailableError() -> NSError {
        NSError(
            domain: NSCocoaErrorDomain,
            code: NSFileWriteOutOfSpaceError,
            userInfo: [
                NSLocalizedDescriptionKey: "iCloud storage is full."
            ]
        )
    }

    // MARK: - SwiftData Errors

    /// SwiftData save error
    static func makeSaveError(reason: String = "Unknown save error") -> NSError {
        NSError(
            domain: "com.afterflow.swiftdata",
            code: 3000,
            userInfo: [
                NSLocalizedDescriptionKey: "Failed to save: \(reason)"
            ]
        )
    }

    /// SwiftData fetch error
    static func makeFetchError(reason: String = "Unknown fetch error") -> NSError {
        NSError(
            domain: "com.afterflow.swiftdata",
            code: 3001,
            userInfo: [
                NSLocalizedDescriptionKey: "Failed to fetch: \(reason)"
            ]
        )
    }

    // MARK: - Validation Errors

    /// Invalid date format error
    static func makeInvalidDateError(dateString: String = "invalid-date") -> NSError {
        NSError(
            domain: "com.afterflow.validation",
            code: 4000,
            userInfo: [
                NSLocalizedDescriptionKey: "Invalid date format: \(dateString)"
            ]
        )
    }

    /// Out of range value error
    static func makeOutOfRangeError(value: Int, min: Int, max: Int) -> NSError {
        NSError(
            domain: "com.afterflow.validation",
            code: 4001,
            userInfo: [
                NSLocalizedDescriptionKey: "Value \(value) is out of range (\(min)-\(max))"
            ]
        )
    }

    /// Missing required field error
    static func makeMissingFieldError(field: String) -> NSError {
        NSError(
            domain: "com.afterflow.validation",
            code: 4002,
            userInfo: [
                NSLocalizedDescriptionKey: "Missing required field: \(field)"
            ]
        )
    }
}
