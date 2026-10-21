import Foundation
import SwiftUI

@MainActor
@Observable
final class ImportState {
    var showingImportPicker = false
    var importError: String?
    var showingImportConfirmation = false
    var pendingImportedSessions: [TherapeuticSession] = []

    var showingRestoreConfirmation = false
    var showingRestoreResult = false
    var pendingBackup: AfterflowBackup?
    var restoreSummary: RestoreSummary?

    private let sessionStore: SessionStore
    private var importTask: Task<Void, Never>?

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
    }

    // MARK: - Picking and routing

    func handleFilePick(_ result: Result<URL, Error>) {
        switch result {
        case let .success(url):
            self.importFile(from: url)
        case let .failure(error):
            self.importError = error.localizedDescription
        }
    }

    func importFile(from url: URL) {
        self.importTask?.cancel()
        self.importTask = Task {
            await self.loadFile(from: url)
        }
    }

    /// Routes by type: backups (`.json`, or content starting with `{`) go to restore
    /// confirmation, everything else is parsed as CSV.
    func loadFile(from url: URL) async {
        self.pendingBackup = nil
        do {
            let data = try await ScopedFileAccess.readData(from: url)
            if Self.isBackupFile(data, at: url) {
                try self.prepareRestore(from: data)
            } else {
                let sessions = try CSVImportService().import(from: data)
                self.pendingImportedSessions = sessions
                self.showingImportConfirmation = !sessions.isEmpty
            }
        } catch is CancellationError {
            return
        } catch {
            self.importError = error.localizedDescription
        }
    }

    private static let leadingWhitespace = Set(" \t\r\n".utf8)

    private static func isBackupFile(_ data: Data, at url: URL) -> Bool {
        if url.pathExtension.lowercased() == "json" { return true }
        guard let first = data.first(where: { !Self.leadingWhitespace.contains($0) }) else { return false }
        return first == UInt8(ascii: "{")
    }

    // MARK: - CSV

    func confirmImport() {
        guard !self.pendingImportedSessions.isEmpty else { return }
        for session in self.pendingImportedSessions {
            do {
                try self.sessionStore.create(session)
            } catch {
                self.importError = "Failed to import session: \(error.localizedDescription)"
            }
        }
        self.pendingImportedSessions = []
    }

    // MARK: - Backup restore

    private func prepareRestore(from data: Data) throws {
        let backup = try BackupService().decode(data)
        guard !backup.sessions.isEmpty else {
            self.importError = "This backup doesn't contain any sessions."
            return
        }
        self.pendingBackup = backup
        self.showingRestoreConfirmation = true
    }

    func cancelRestore() {
        self.pendingBackup = nil
    }

    func confirmRestore() {
        guard let backup = self.pendingBackup else { return }
        self.pendingBackup = nil
        do {
            self.restoreSummary = try self.sessionStore.restore(from: backup)
            self.showingRestoreResult = true
        } catch {
            // Store errors are not surfaced verbatim; they could quote stored values.
            self.importError = "The backup couldn't be restored. No changes were made to your sessions."
        }
    }

    var restoreConfirmationMessage: String {
        guard let backup = self.pendingBackup else { return "" }
        let count = backup.sessions.count
        let noun = count == 1 ? "session" : "sessions"
        let date = backup.exportedAt.formatted(date: .abbreviated, time: .omitted)
        return "Restore \(count) \(noun) from a backup made on \(date)? "
            + "Sessions already here are kept; matching ones are updated only if the backup is newer."
    }

    var restoreResultMessage: String {
        guard let summary = self.restoreSummary else { return "" }
        return "\(summary.inserted) added, \(summary.updated) updated, \(summary.skipped) already up to date."
    }
}
