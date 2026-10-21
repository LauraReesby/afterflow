import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
@Observable
final class BackupState {
    static let lastBackupDateKey = "afterflow.backup.lastBackupDate"

    var showingBackupExporter = false
    var backupDocument: BinaryFileDocument?
    var backupFilename = "Afterflow-Backup"
    var backupError: String?
    private(set) var lastBackupDate: Date?

    var showingRestorePicker = false
    var showingRestoreConfirmation = false
    var showingRestoreResult = false
    var pendingBackup: AfterflowBackup?
    var restoreSummary: RestoreSummary?
    var restoreError: String?

    private let defaults: UserDefaults
    private var restoreTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.lastBackupDate = defaults.object(forKey: Self.lastBackupDateKey) as? Date
    }

    // MARK: - Back up

    /// Prepares the backup file and presents the exporter. Nothing is recorded as
    /// "last backed up" until the exporter reports that the file was saved.
    func startBackup(sessions: [TherapeuticSession]) {
        self.backupError = nil
        do {
            let data = try BackupService().encode(sessions: sessions)
            self.backupDocument = BinaryFileDocument(data: data, contentType: .json)
            self.backupFilename = BackupService.filename(for: Date())
            self.showingBackupExporter = true
        } catch {
            self.backupError = error.localizedDescription
        }
    }

    func handleBackupExport(_ result: Result<URL, Error>, at date: Date = Date()) {
        self.backupDocument = nil
        switch result {
        case .success:
            self.defaults.set(date, forKey: Self.lastBackupDateKey)
            self.lastBackupDate = date
        case let .failure(error):
            if (error as? CocoaError)?.code != .userCancelled {
                self.backupError = error.localizedDescription
            }
        }
    }

    // MARK: - Restore

    func handleRestorePick(_ result: Result<URL, Error>) {
        switch result {
        case let .success(url):
            self.prepareRestore(from: url)
        case let .failure(error):
            self.restoreError = error.localizedDescription
        }
    }

    func prepareRestore(from url: URL) {
        self.restoreTask?.cancel()
        self.restoreTask = Task {
            await self.loadBackup(from: url)
        }
    }

    func loadBackup(from url: URL) async {
        self.restoreError = nil
        self.pendingBackup = nil
        do {
            let data = try await ScopedFileAccess.readData(from: url)
            let backup = try BackupService().decode(data)
            guard !backup.sessions.isEmpty else {
                self.restoreError = "This backup doesn't contain any sessions."
                return
            }
            self.pendingBackup = backup
            self.showingRestoreConfirmation = true
        } catch is CancellationError {
            return
        } catch {
            self.restoreError = error.localizedDescription
        }
    }

    func cancelRestore() {
        self.pendingBackup = nil
    }

    func confirmRestore(into sessionStore: SessionStore) {
        guard let backup = self.pendingBackup else { return }
        self.pendingBackup = nil
        do {
            self.restoreSummary = try sessionStore.restore(from: backup)
            self.showingRestoreResult = true
        } catch {
            // Store errors are not surfaced verbatim; they could quote stored values.
            self.restoreError = "The backup couldn't be restored. No changes were made to your sessions."
        }
    }

    var restoreConfirmationMessage: String {
        guard let backup = self.pendingBackup else { return "" }
        let count = backup.sessions.count
        let noun = count == 1 ? "session" : "sessions"
        let date = backup.exportedAt.formatted(date: .abbreviated, time: .omitted)
        return "Restore \(count) \(noun) from \(date)? "
            + "Existing sessions are kept; matching sessions are updated only if the backup is newer."
    }

    var restoreResultMessage: String {
        guard let summary = self.restoreSummary else { return "" }
        return "\(summary.inserted) added, \(summary.updated) updated, \(summary.skipped) already up to date."
    }

    // MARK: - Status

    static func lastBackupText(for date: Date?, now: Date = Date()) -> String {
        guard let date else { return "Not backed up yet" }
        guard now.timeIntervalSince(date) >= 60 else { return "Last backup: just now" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Last backup: \(formatter.localizedString(for: date, relativeTo: now))"
    }
}
