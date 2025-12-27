@testable import Afterflow
import Foundation


enum ErrorFixtureFactory {
    

    
    static func makeInvalidHeaderError() -> CSVImportService.CSVImportError {
        .invalidHeader
    }

    
    static func makeInvalidRowError(row: Int = 1) -> CSVImportService.CSVImportError {
        .invalidRow(row)
    }

    
    static func makeParseFailureError(reason: String = "Parse failed") -> CSVImportService.CSVImportError {
        .parseFailure(reason)
    }

    

    
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

    
    static func makeDiskFullError() -> NSError {
        NSError(
            domain: NSCocoaErrorDomain,
            code: NSFileWriteOutOfSpaceError,
            userInfo: [
                NSLocalizedDescriptionKey: "The operation couldn't be completed because the disk is full."
            ]
        )
    }

    

    
    static func makeTimeoutError() -> NSError {
        NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorTimedOut,
            userInfo: [
                NSLocalizedDescriptionKey: "The request timed out."
            ]
        )
    }

    
    static func makeNoConnectionError() -> NSError {
        NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [
                NSLocalizedDescriptionKey: "The Internet connection appears to be offline."
            ]
        )
    }

    

    
    static func makeExportFailureError(reason: String = "Unknown export error") -> NSError {
        NSError(
            domain: "com.afterflow.export",
            code: 1000,
            userInfo: [
                NSLocalizedDescriptionKey: "Export failed: \(reason)"
            ]
        )
    }

    
    static func makeInvalidFormatError(format: String = "unknown") -> NSError {
        NSError(
            domain: "com.afterflow.export",
            code: 1001,
            userInfo: [
                NSLocalizedDescriptionKey: "Invalid export format: \(format)"
            ]
        )
    }

    

    
    static func makeParseError(line: Int = 1, column: Int = 1) -> NSError {
        NSError(
            domain: "com.afterflow.import",
            code: 2000,
            userInfo: [
                NSLocalizedDescriptionKey: "Parse error at line \(line), column \(column)"
            ]
        )
    }

    
    static func makeEncodingError(encoding: String = "UTF-8") -> NSError {
        NSError(
            domain: NSCocoaErrorDomain,
            code: NSFileReadInapplicableStringEncodingError,
            userInfo: [
                NSLocalizedDescriptionKey: "The data couldn't be read because it isn't in the correct format (\(encoding))."
            ]
        )
    }

    

    
    static func makeSecurityScopedResourceError() -> NSError {
        NSError(
            domain: NSCocoaErrorDomain,
            code: NSFileReadNoPermissionError,
            userInfo: [
                NSLocalizedDescriptionKey: "The app doesn't have permission to access this file."
            ]
        )
    }

    

    
    static func makeICloudDownloadError() -> NSError {
        NSError(
            domain: NSCocoaErrorDomain,
            code: NSFileReadUnknownError,
            userInfo: [
                NSLocalizedDescriptionKey: "The file is not currently available from iCloud."
            ]
        )
    }

    
    static func makeICloudUnavailableError() -> NSError {
        NSError(
            domain: NSCocoaErrorDomain,
            code: NSFileWriteOutOfSpaceError,
            userInfo: [
                NSLocalizedDescriptionKey: "iCloud storage is full."
            ]
        )
    }

    

    
    static func makeSaveError(reason: String = "Unknown save error") -> NSError {
        NSError(
            domain: "com.afterflow.swiftdata",
            code: 3000,
            userInfo: [
                NSLocalizedDescriptionKey: "Failed to save: \(reason)"
            ]
        )
    }

    
    static func makeFetchError(reason: String = "Unknown fetch error") -> NSError {
        NSError(
            domain: "com.afterflow.swiftdata",
            code: 3001,
            userInfo: [
                NSLocalizedDescriptionKey: "Failed to fetch: \(reason)"
            ]
        )
    }

    

    
    static func makeInvalidDateError(dateString: String = "invalid-date") -> NSError {
        NSError(
            domain: "com.afterflow.validation",
            code: 4000,
            userInfo: [
                NSLocalizedDescriptionKey: "Invalid date format: \(dateString)"
            ]
        )
    }

    
    static func makeOutOfRangeError(value: Int, min: Int, max: Int) -> NSError {
        NSError(
            domain: "com.afterflow.validation",
            code: 4001,
            userInfo: [
                NSLocalizedDescriptionKey: "Value \(value) is out of range (\(min)-\(max))"
            ]
        )
    }

    
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
