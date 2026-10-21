import Foundation
import SwiftUI

@MainActor
@Observable
final class ImportState {
    var showingImportPicker = false
    var importError: String?
    var showingImportConfirmation = false
    var pendingImportedSessions: [TherapeuticSession] = []

    private let sessionStore: SessionStore

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
    }

    func importCSV(from url: URL) {
        Task {
            let didStart = url.startAccessingSecurityScopedResource()
            defer {
                if didStart {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                try await ScopedFileAccess.downloadIfNeeded(url: url)
                let sessions = try CSVImportService().import(from: url)
                self.pendingImportedSessions = sessions
                self.showingImportConfirmation = !sessions.isEmpty
            } catch {
                self.importError = error.localizedDescription
            }
        }
    }

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
}
