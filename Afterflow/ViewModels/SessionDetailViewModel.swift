//  Constitutional Compliance: Therapeutic Tone, Offline-First

import Foundation
import Observation

protocol SessionReflectionPersisting {
    func updateSession(_ session: TherapeuticSession) throws
}

@MainActor
@Observable
final class SessionDetailViewModel {
    private let session: TherapeuticSession
    private let persistence: SessionReflectionPersisting

    var reflectionText: String
    var administration: AdministrationMethod
    var environmentNotes: String
    var musicNotes: String
    var moodBefore: Int
    var moodAfter: Int
    var isSaving = false
    var errorMessage: String?
    var showSuccessMessage = false

    init(session: TherapeuticSession, persistence: SessionReflectionPersisting) {
        self.session = session
        self.persistence = persistence
        self.reflectionText = session.reflections
        self.administration = session.administration
        self.environmentNotes = session.environmentNotes
        self.musicNotes = session.musicNotes
        self.moodBefore = session.moodBefore
        self.moodAfter = session.moodAfter
    }

    var hasChanges: Bool {
        let trimmedReflection = self.reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedReflection != self.session.reflections ||
            self.administration != self.session.administration ||
            self.environmentNotes != self.session.environmentNotes ||
            self.musicNotes != self.session.musicNotes ||
            self.moodBefore != self.session.moodBefore ||
            self.moodAfter != self.session.moodAfter
    }

    func saveReflection() {
        guard self.hasChanges else { return }
        self.isSaving = true
        self.errorMessage = nil
        self.showSuccessMessage = false

        let trimmed = self.reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.session.reflections = trimmed
        self.session.administration = self.administration
        self.session.environmentNotes = self.environmentNotes
        self.session.musicNotes = self.musicNotes
        self.session.moodBefore = self.moodBefore
        self.session.moodAfter = self.moodAfter

        do {
            if !trimmed.isEmpty {
                self.session.reminderDate = nil
            }
            try self.persistence.updateSession(self.session)
            self.reflectionText = trimmed
            self.showSuccessMessage = true
        } catch {
            self.errorMessage = "Couldn't save reflection: \(error.localizedDescription)"
            // Revert on failure to previous values
            self.session.reflections = self.reflectionText
        }

        self.isSaving = false
    }

    func dismissSuccessMessage() {
        self.showSuccessMessage = false
    }
}
