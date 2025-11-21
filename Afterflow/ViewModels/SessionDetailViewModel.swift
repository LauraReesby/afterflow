//  Constitutional Compliance: Therapeutic Tone, Offline-First

import Foundation
import Observation

protocol SessionReflectionPersisting {
    func updateSession(_ session: TherapeuticSession) throws
}

extension SessionDataService: SessionReflectionPersisting {}

@MainActor
@Observable
final class SessionDetailViewModel {
    private let session: TherapeuticSession
    private let persistence: SessionReflectionPersisting

    var reflectionText: String
    var isSaving = false
    var errorMessage: String?
    var showSuccessMessage = false

    init(session: TherapeuticSession, persistence: SessionReflectionPersisting) {
        self.session = session
        self.persistence = persistence
        self.reflectionText = session.reflections
    }

    var helperCopy: String {
        "Capture integration notes, grounding reminders, or insights you'd like to revisit."
    }

    var hasChanges: Bool {
        self.reflectionText.trimmingCharacters(in: .whitespacesAndNewlines) != self.session.reflections
    }

    func saveReflection() {
        guard self.hasChanges else { return }
        self.isSaving = true
        self.errorMessage = nil
        self.showSuccessMessage = false

        let trimmed = self.reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.session.reflections = trimmed

        do {
            self.session.status = .complete
            self.session.reminderDate = nil
            try self.persistence.updateSession(self.session)
            self.reflectionText = trimmed
            self.showSuccessMessage = true
        } catch {
            self.errorMessage = "Couldn't save reflection: \(error.localizedDescription)"
            self.session.reflections = self.reflectionText
        }

        self.isSaving = false
    }

    func dismissSuccessMessage() {
        self.showSuccessMessage = false
    }
}
