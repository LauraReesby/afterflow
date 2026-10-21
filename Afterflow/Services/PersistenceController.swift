import Foundation
import SwiftData

/// Opens the on-disk SwiftData store and owns the file-level recovery operations
/// (save a copy, quarantine). Opening never crashes: failure is returned so the app
/// can show a recovery screen instead of leaving the user's data unreachable.
struct PersistenceController {
    static let storeFileName = "default.store"
    static let recoveryFolderName = "Afterflow-Recovered"
    static let exportFolderName = "Afterflow-Data-Copy"

    /// Same location SwiftData uses implicitly, so existing installs are unaffected.
    static var defaultStoreURL: URL {
        URL.applicationSupportDirectory.appending(path: self.storeFileName)
    }

    static var defaultRecoveryRootURL: URL {
        URL.applicationSupportDirectory.appending(path: self.recoveryFolderName)
    }

    let storeURL: URL
    let recoveryRootURL: URL
    let temporaryRootURL: URL
    let isStoredInMemoryOnly: Bool

    init(
        storeURL: URL = PersistenceController.defaultStoreURL,
        recoveryRootURL: URL = PersistenceController.defaultRecoveryRootURL,
        temporaryRootURL: URL = FileManager.default.temporaryDirectory,
        isStoredInMemoryOnly: Bool = false
    ) {
        self.storeURL = storeURL
        self.recoveryRootURL = recoveryRootURL
        self.temporaryRootURL = temporaryRootURL
        self.isStoredInMemoryOnly = isStoredInMemoryOnly
    }

    /// Controller for the running process. `-ui-testing` keeps the store in memory and
    /// resets UserDefaults, exactly as the app did before this type existed.
    static func forLaunch(arguments: [String] = ProcessInfo.processInfo.arguments) -> PersistenceController {
        let isUITesting = arguments.contains("-ui-testing")
        if isUITesting, let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        return PersistenceController(isStoredInMemoryOnly: isUITesting)
    }

    // MARK: - Opening

    func open() -> Result<ModelContainer, Error> {
        do {
            if !self.isStoredInMemoryOnly {
                try FileManager.default.createDirectory(
                    at: self.storeURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
            }
            let schema = Schema(versionedSchema: AfterflowSchemaV1.self)
            let configuration = if self.isStoredInMemoryOnly {
                ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            } else {
                ModelConfiguration(schema: schema, url: self.storeURL)
            }
            let container = try ModelContainer(
                for: schema,
                migrationPlan: AfterflowMigrationPlan.self,
                configurations: [configuration]
            )
            return .success(container)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Store files

    /// The store file plus its SQLite write-ahead-log siblings, in a stable order.
    var storeFileURLs: [URL] {
        ["", "-wal", "-shm"].map { URL(fileURLWithPath: self.storeURL.path + $0) }
    }

    /// Only the store files that currently exist on disk.
    var existingStoreFileURLs: [URL] {
        self.storeFileURLs.filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    /// Copies the existing store files into a fresh folder under `temporaryRootURL`,
    /// replacing any earlier copy, and returns the copies. The originals are untouched.
    func makeExportCopy() throws -> [URL] {
        let fileManager = FileManager.default
        let folder = self.temporaryRootURL.appending(path: Self.exportFolderName)
        try? fileManager.removeItem(at: folder)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

        return try self.existingStoreFileURLs.map { source in
            let destination = folder.appending(path: source.lastPathComponent)
            try fileManager.copyItem(at: source, to: destination)
            return destination
        }
    }

    func removeExportCopy() {
        try? FileManager.default.removeItem(at: self.temporaryRootURL.appending(path: Self.exportFolderName))
    }

    /// Moves (never deletes) the existing store files into a timestamped folder under
    /// `recoveryRootURL`, so the next `open()` creates a new empty store. If any move fails,
    /// files already moved are put back and the error is rethrown.
    @discardableResult func quarantineStoreFiles(at date: Date = Date()) throws -> URL {
        let fileManager = FileManager.default
        let folder = self.uniqueRecoveryFolder(for: date)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

        var moved: [(from: URL, to: URL)] = []
        do {
            for source in self.existingStoreFileURLs {
                let destination = folder.appending(path: source.lastPathComponent)
                try fileManager.moveItem(at: source, to: destination)
                moved.append((from: source, to: destination))
            }
        } catch {
            for entry in moved.reversed() {
                try? fileManager.moveItem(at: entry.to, to: entry.from)
            }
            // Never delete data: drop the folder only if rolling back left it empty.
            if let leftovers = try? fileManager.contentsOfDirectory(atPath: folder.path), leftovers.isEmpty {
                try? fileManager.removeItem(at: folder)
            }
            throw error
        }
        return folder
    }

    private func uniqueRecoveryFolder(for date: Date) -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH-mm-ss'Z'"
        let base = formatter.string(from: date)

        var candidate = self.recoveryRootURL.appending(path: base)
        var suffix = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = self.recoveryRootURL.appending(path: "\(base)-\(suffix)")
            suffix += 1
        }
        return candidate
    }
}
