import Foundation

/// Lossless, versioned snapshot of every session. Unlike the CSV export, which is
/// a report, this keeps ids, timestamps, reminders and music metadata so a restore
/// can match sessions instead of duplicating them.
nonisolated struct AfterflowBackup: Codable, Equatable {
    static let currentFormatVersion = 1

    let formatVersion: Int
    let exportedAt: Date
    let appVersion: String?
    let sessions: [SessionBackupRecord]
}

/// Mirrors every stored property of `TherapeuticSession`. Enum-backed fields keep
/// their raw strings so values written by a future version survive a round-trip.
nonisolated struct SessionBackupRecord: Codable, Equatable {
    let id: UUID
    let sessionDate: Date
    let treatmentTypeRawValue: String
    let administrationRawValue: String
    let intention: String
    let createdAt: Date
    let updatedAt: Date
    let moodBefore: Int
    let moodAfter: Int?
    let reflections: String
    let reminderDate: Date?
    let musicLinkURL: String?
    let musicLinkWebURL: String?
    let musicLinkTitle: String?
    let musicLinkAuthorName: String?
    let musicLinkArtworkURL: String?
    let musicLinkDurationSeconds: Int?
    let musicLinkProviderRawValue: String?
}

extension SessionBackupRecord {
    @MainActor init(session: TherapeuticSession) {
        self.init(
            id: session.id,
            sessionDate: session.sessionDate,
            treatmentTypeRawValue: session.treatmentTypeRawValue,
            administrationRawValue: session.administrationRawValue,
            intention: session.intention,
            createdAt: session.createdAt,
            updatedAt: session.updatedAt,
            moodBefore: session.moodBefore,
            moodAfter: session.moodAfter,
            reflections: session.reflections,
            reminderDate: session.reminderDate,
            musicLinkURL: session.musicLinkURL,
            musicLinkWebURL: session.musicLinkWebURL,
            musicLinkTitle: session.musicLinkTitle,
            musicLinkAuthorName: session.musicLinkAuthorName,
            musicLinkArtworkURL: session.musicLinkArtworkURL,
            musicLinkDurationSeconds: session.musicLinkDurationSeconds,
            musicLinkProviderRawValue: session.musicLinkProviderRawValue
        )
    }

    /// A new, uninserted session carrying this record's id and timestamps.
    @MainActor func makeSession() -> TherapeuticSession {
        let session = TherapeuticSession()
        session.id = self.id
        self.apply(to: session)
        return session
    }

    /// Overwrites every field of `session` except its id. Timestamps are copied
    /// verbatim; `markAsUpdated()` is deliberately not called.
    @MainActor func apply(to session: TherapeuticSession) {
        session.sessionDate = self.sessionDate
        session.treatmentTypeRawValue = self.treatmentTypeRawValue
        session.administrationRawValue = self.administrationRawValue
        session.intention = self.intention
        session.createdAt = self.createdAt
        session.updatedAt = self.updatedAt
        session.moodBefore = self.moodBefore
        session.moodAfter = self.moodAfter
        session.reflections = self.reflections
        session.reminderDate = self.reminderDate
        session.musicLinkURL = self.musicLinkURL
        session.musicLinkWebURL = self.musicLinkWebURL
        session.musicLinkTitle = self.musicLinkTitle
        session.musicLinkAuthorName = self.musicLinkAuthorName
        session.musicLinkArtworkURL = self.musicLinkArtworkURL
        session.musicLinkDurationSeconds = self.musicLinkDurationSeconds
        session.musicLinkProviderRawValue = self.musicLinkProviderRawValue
    }
}

nonisolated struct RestoreSummary: Equatable {
    var inserted = 0
    var updated = 0
    var skipped = 0
}

/// Messages are fixed strings; they never echo file or session contents.
nonisolated enum BackupError: Error, LocalizedError, Equatable {
    case invalidFile
    case unsupportedVersion(Int)
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidFile:
            "This file isn't a valid Afterflow backup."
        case .unsupportedVersion:
            "This backup was made by a newer version of Afterflow. Update the app to restore it."
        case .encodingFailed:
            "The backup couldn't be created."
        }
    }
}
