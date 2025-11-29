import Foundation
import Observation
import SwiftData

/// Observable store that manages session persistence and reminder scheduling.
@MainActor
@Observable
final class SessionStore {
    private let modelContext: ModelContext
    private let reminderScheduler: ReminderScheduler
    private let owningContainer: ModelContainer?
    private let draftDefaults: UserDefaults
    private let draftPayloadKey = "session_draft_payload"
    private let draftTimestampKey = "session_draft_timestamp"

    var sessions: [TherapeuticSession] = []

    init(
        modelContext: ModelContext,
        owningContainer: ModelContainer? = nil,
        reminderScheduler: ReminderScheduler? = nil,
        draftDefaults: UserDefaults = .standard
    ) {
        self.modelContext = modelContext
        self.owningContainer = owningContainer
        self.reminderScheduler = reminderScheduler ?? ReminderScheduler()
        self.draftDefaults = draftDefaults
        self.reload()
    }

    func reload() {
        let descriptor = FetchDescriptor<TherapeuticSession>(
            sortBy: [SortDescriptor(\.sessionDate, order: .reverse)]
        )
        if let fetched = try? modelContext.fetch(descriptor) {
            self.sessions = fetched
        }
    }

    func create(_ session: TherapeuticSession) throws {
        modelContext.insert(session)
        try saveAndRefresh()
        Task { await self.scheduleReminderIfNeeded(for: session) }
    }

    func update(_ session: TherapeuticSession) throws {
        session.markAsUpdated()
        try saveAndRefresh()
        Task { await self.scheduleReminderIfNeeded(for: session) }
    }

    func delete(_ session: TherapeuticSession) throws {
        reminderScheduler.cancelReminder(for: session)
        modelContext.delete(session)
        try saveAndRefresh()
    }

    func setReminder(for session: TherapeuticSession, option: ReminderOption) async throws {
        await reminderScheduler.setReminder(for: session, option: option)
        if modelContext.hasChanges {
            try modelContext.save()
        }
        self.reload()
    }

    // MARK: - Helpers

    private func saveAndRefresh() throws {
        if modelContext.hasChanges {
            try modelContext.save()
        }
        self.reload()
    }

    private func scheduleReminderIfNeeded(for session: TherapeuticSession) async {
        switch session.status {
        case .needsReflection:
            if session.reminderDate == nil {
                reminderScheduler.cancelReminder(for: session)
            }
        case .draft, .complete:
            reminderScheduler.cancelReminder(for: session)
        }
    }

    // MARK: - Draft Persistence (lightweight)

    func saveDraft(_ session: TherapeuticSession) {
        do {
            let draft = SessionDraft(session: session)
            let data = try JSONEncoder().encode(draft)
            draftDefaults.set(data, forKey: draftPayloadKey)
            draftDefaults.set(Date(), forKey: draftTimestampKey)
        } catch {
            print("Failed to save draft: \(error.localizedDescription)")
        }
    }

    func recoverDraft() -> TherapeuticSession? {
        guard
            let timestamp = draftDefaults.object(forKey: draftTimestampKey) as? Date,
            let data = draftDefaults.data(forKey: draftPayloadKey)
        else { return nil }

        // Only keep drafts for 24 hours
        let hoursSinceSave = Date().timeIntervalSince(timestamp) / 3600
        guard hoursSinceSave < 24 else {
            clearDraft()
            return nil
        }

        do {
            let draft = try JSONDecoder().decode(SessionDraft.self, from: data)
            return draft.makeSession()
        } catch {
            print("Failed to recover draft: \(error.localizedDescription)")
            clearDraft()
            return nil
        }
    }

    func clearDraft() {
        draftDefaults.removeObject(forKey: draftPayloadKey)
        draftDefaults.removeObject(forKey: draftTimestampKey)
    }
}

// Allow view models to depend on a narrow persistence surface.
extension SessionStore: SessionReflectionPersisting {
    func updateSession(_ session: TherapeuticSession) throws {
        try self.update(session)
    }
}

// MARK: - Draft DTO

private struct SessionDraft: Codable {
    let sessionDate: Date
    let treatmentType: String
    let administration: String
    let intention: String
    let environmentNotes: String
    let musicNotes: String
    let moodBefore: Int
    let moodAfter: Int
    let reflections: String
    let spotifyPlaylistURI: String?
    let spotifyPlaylistName: String?
    let spotifyPlaylistImageURL: String?
    let reminderDate: Date?

    init(session: TherapeuticSession) {
        self.sessionDate = session.sessionDate
        self.treatmentType = session.treatmentTypeRawValue
        self.administration = session.administrationRawValue
        self.intention = session.intention
        self.environmentNotes = session.environmentNotes
        self.musicNotes = session.musicNotes
        self.moodBefore = session.moodBefore
        self.moodAfter = session.moodAfter
        self.reflections = session.reflections
        self.spotifyPlaylistURI = session.spotifyPlaylistURI
        self.spotifyPlaylistName = session.spotifyPlaylistName
        self.spotifyPlaylistImageURL = session.spotifyPlaylistImageURL
        self.reminderDate = session.reminderDate
    }

    func makeSession() -> TherapeuticSession {
        let session = TherapeuticSession(
            sessionDate: sessionDate,
            treatmentType: PsychedelicTreatmentType(rawValue: treatmentType) ?? .psilocybin,
            administration: AdministrationMethod(rawValue: administration) ?? .oral,
            intention: intention,
            environmentNotes: environmentNotes,
            musicNotes: musicNotes,
            moodBefore: moodBefore,
            moodAfter: moodAfter,
            reflections: reflections,
            reminderDate: reminderDate
        )
        session.spotifyPlaylistURI = spotifyPlaylistURI
        session.spotifyPlaylistName = spotifyPlaylistName
        session.spotifyPlaylistImageURL = spotifyPlaylistImageURL
        return session
    }
}
