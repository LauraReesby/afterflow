import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class SessionStore {
    private let modelContext: ModelContext
    private let reminderScheduler: ReminderScheduler
    private let owningContainer: ModelContainer?
    private let draftDefaults: UserDefaults
    private let draftPayloadKey = "session_draft_payload"
    private let draftTimestampKey = "session_draft_timestamp"

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
    }

    func create(_ session: TherapeuticSession) throws {
        self.modelContext.insert(session)
        try self.modelContext.save()
        self.scheduleReminderIfNeeded(for: session)
    }

    func update(_ session: TherapeuticSession) throws {
        session.markAsUpdated()
        try self.modelContext.save()
        self.scheduleReminderIfNeeded(for: session)
    }

    func delete(_ session: TherapeuticSession) throws {
        self.reminderScheduler.cancelReminder(for: session)
        self.modelContext.delete(session)
        try self.modelContext.save()
    }

    /// Merges a backup into the store: inserts unknown ids, overwrites a session only
    /// when the backup's `updatedAt` is newer, and never deletes. All changes land in
    /// one save, so a failure leaves the store untouched. Reminders are not rescheduled.
    func restore(from backup: AfterflowBackup) throws -> RestoreSummary {
        let existing = try self.modelContext.fetch(FetchDescriptor<TherapeuticSession>())
        var sessionsByID: [UUID: TherapeuticSession] = Dictionary(
            existing.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        var summary = RestoreSummary()

        for record in backup.sessions {
            if let session = sessionsByID[record.id] {
                if record.updatedAt > session.updatedAt {
                    record.apply(to: session)
                    summary.updated += 1
                } else {
                    summary.skipped += 1
                }
            } else {
                let session = record.makeSession()
                self.modelContext.insert(session)
                sessionsByID[record.id] = session
                summary.inserted += 1
            }
        }

        guard summary.inserted + summary.updated > 0 else { return summary }
        do {
            try self.modelContext.save()
        } catch {
            self.modelContext.rollback()
            throw error
        }
        return summary
    }

    func setReminder(for session: TherapeuticSession, option: ReminderOption) async throws {
        try await self.reminderScheduler.setReminder(for: session, option: option)
        if self.modelContext.hasChanges {
            try self.modelContext.save()
        }
    }

    private func scheduleReminderIfNeeded(for session: TherapeuticSession) {
        switch session.status {
        case .needsReflection:
            if session.reminderDate == nil {
                self.reminderScheduler.cancelReminder(for: session)
            }
        case .draft, .complete:
            self.reminderScheduler.cancelReminder(for: session)
        }
    }

    func saveDraft(_ session: TherapeuticSession) {
        do {
            let draft = SessionDraft(session: session)
            let data = try JSONEncoder().encode(draft)
            self.draftDefaults.set(data, forKey: self.draftPayloadKey)
            self.draftDefaults.set(Date(), forKey: self.draftTimestampKey)
        } catch {}
    }

    func recoverDraft() -> TherapeuticSession? {
        guard let timestamp = draftDefaults.object(forKey: draftTimestampKey) as? Date,
              let data = draftDefaults.data(forKey: draftPayloadKey)
        else { return nil }

        let hoursSinceSave = Date().timeIntervalSince(timestamp) / 3600
        guard hoursSinceSave < 24 else {
            self.clearDraft()
            return nil
        }

        do {
            let draft = try JSONDecoder().decode(SessionDraft.self, from: data)
            return draft.makeSession()
        } catch {
            self.clearDraft()
            return nil
        }
    }

    func clearDraft() {
        self.draftDefaults.removeObject(forKey: self.draftPayloadKey)
        self.draftDefaults.removeObject(forKey: self.draftTimestampKey)
    }
}

private struct SessionDraft: Codable {
    let sessionDate: Date
    let treatmentType: String
    let administration: String
    let intention: String
    let moodBefore: Int
    let moodAfter: Int?
    let reflections: String
    let musicLinkURL: String?
    let musicLinkWebURL: String?
    let musicLinkTitle: String?
    let musicLinkAuthorName: String?
    let musicLinkArtworkURL: String?
    let musicLinkProviderRawValue: String?
    let musicLinkDurationSeconds: Int?
    let reminderDate: Date?

    init(session: TherapeuticSession) {
        self.sessionDate = session.sessionDate
        self.treatmentType = session.treatmentTypeRawValue
        self.administration = session.administrationRawValue
        self.intention = session.intention
        self.moodBefore = session.moodBefore
        self.moodAfter = session.moodAfter
        self.reflections = session.reflections
        self.musicLinkURL = session.musicLinkURL
        self.musicLinkWebURL = session.musicLinkWebURL
        self.musicLinkTitle = session.musicLinkTitle
        self.musicLinkAuthorName = session.musicLinkAuthorName
        self.musicLinkArtworkURL = session.musicLinkArtworkURL
        self.musicLinkProviderRawValue = session.musicLinkProviderRawValue
        self.musicLinkDurationSeconds = session.musicLinkDurationSeconds
        self.reminderDate = session.reminderDate
    }

    func makeSession() -> TherapeuticSession {
        let session = TherapeuticSession(
            sessionDate: sessionDate,
            treatmentType: PsychedelicTreatmentType(rawValue: treatmentType) ?? .psilocybin,
            administration: AdministrationMethod(rawValue: administration) ?? .oral,
            intention: intention,
            moodBefore: moodBefore,
            moodAfter: moodAfter,
            reflections: reflections,
            reminderDate: reminderDate
        )
        session.musicLinkURL = self.musicLinkURL
        session.musicLinkWebURL = self.musicLinkWebURL
        session.musicLinkTitle = self.musicLinkTitle
        session.musicLinkAuthorName = self.musicLinkAuthorName
        session.musicLinkArtworkURL = self.musicLinkArtworkURL
        session.musicLinkProviderRawValue = self.musicLinkProviderRawValue
        session.musicLinkDurationSeconds = self.musicLinkDurationSeconds
        return session
    }
}
