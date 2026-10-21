import Foundation
import SwiftUI

@MainActor
@Observable
final class ImportState {
    var showingImportPicker = false
    var importError: String?
    var showingImportConfirmation = false
    var pendingImportResult: CSVImportResult?
    var showingImportResult = false
    var importSummary: CSVImportSummary?

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
        self.pendingImportResult = nil
        do {
            let data = try await ScopedFileAccess.readData(from: url)
            if Self.isBackupFile(data, at: url) {
                try self.prepareRestore(from: data)
            } else {
                try self.prepareImport(from: data)
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

    private static let maxListedSkippedRows = 5

    private func prepareImport(from data: Data) throws {
        let result = try CSVImportService().importDetailed(from: data)
        guard !result.sessions.isEmpty else {
            self.importError = "No sessions were found in this file."
            return
        }
        self.pendingImportResult = result
        self.showingImportConfirmation = true
    }

    func confirmImport() {
        guard let result = self.pendingImportResult else { return }
        self.pendingImportResult = nil
        self.showingImportConfirmation = false
        do {
            self.importSummary = try self.sessionStore.importSessions(result.sessions)
            self.showingImportResult = true
        } catch {
            // Store errors are not surfaced verbatim; they could quote stored values.
            self.importError = "The sessions couldn't be imported. No changes were made."
        }
    }

    func cancelImport() {
        self.pendingImportResult = nil
        self.showingImportConfirmation = false
    }

    var importButtonTitle: String {
        let count = self.pendingImportResult?.sessions.count ?? 0
        return count == 1 ? "Import 1 Session" : "Import \(count) Sessions"
    }

    var importConfirmationMessage: String {
        guard let result = self.pendingImportResult else { return "" }
        return Self.confirmationMessage(for: result)
    }

    var importResultMessage: String {
        guard let summary = self.importSummary else { return "" }
        return "\(summary.insertedCount) added, \(summary.skippedDuplicateCount) already in Afterflow."
    }

    /// One short sentence per thing the user should know. Only line numbers and counts appear, never cell contents.
    static func confirmationMessage(for result: CSVImportResult) -> String {
        let count = result.sessions.count
        var lines = ["Import \(count) \(Self.noun(count, "session", "sessions")) from this file?"]
        lines.append(Self.skippedRowsLine(result.skippedRows))
        lines.append(Self.defaultedMoodLine(result.defaultedMoodBeforeCount))
        lines.append(Self.unrecognisedLine(result.unrecognisedTreatmentCount, "treatment", "treatments"))
        lines.append(Self.unrecognisedLine(
            result.unrecognisedAdministrationCount,
            "administration method",
            "administration methods"
        ))
        lines.append("Sessions already in Afterflow will be skipped.")
        return lines.filter { !$0.isEmpty }.joined(separator: "\n")
    }

    /// The helpers below return an empty string when their line does not apply.
    private static func skippedRowsLine(_ skippedRows: [CSVImportSkippedRow]) -> String {
        guard !skippedRows.isEmpty else { return "" }
        let count = skippedRows.count
        let rows = Self.skippedRowList(skippedRows.map(\.line))
        return "\(count) \(Self.noun(count, "row", "rows")) couldn't be read and will be skipped (\(rows))."
    }

    private static func defaultedMoodLine(_ count: Int) -> String {
        guard count > 0 else { return "" }
        let subject = Self.noun(count, "session had", "sessions had")
        return "\(count) \(subject) no mood before; it will be set to \(CSVImportService.defaultMoodBefore)."
    }

    private static func noun(_ count: Int, _ singular: String, _ plural: String) -> String {
        count == 1 ? singular : plural
    }

    /// `row 4`, `rows 4, 9, 12` or, past the cap, `rows 4, 9, 12, 15, 17 and 3 more`.
    private static func skippedRowList(_ lines: [Int]) -> String {
        let listed = lines.prefix(Self.maxListedSkippedRows).map { String($0) }.joined(separator: ", ")
        let remaining = lines.count - Self.maxListedSkippedRows
        let tail = remaining > 0 ? " and \(remaining) more" : ""
        return "\(Self.noun(lines.count, "row", "rows")) \(listed)\(tail)"
    }

    private static func unrecognisedLine(_ count: Int, _ singular: String, _ plural: String) -> String {
        guard count > 0 else { return "" }
        let destination = "saved as Other with the original name added to the reflections."
        if count == 1 {
            return "1 \(singular) wasn't recognised; it'll be \(destination)"
        }
        return "\(count) \(plural) weren't recognised; they'll be \(destination)"
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
