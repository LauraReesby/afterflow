//  Constitutional Compliance: Privacy-First, SwiftData Native, Offline-First

import Foundation
import SwiftData

/// Supported psychedelic treatment types for therapeutic sessions
enum PsychedelicTreatmentType: String, CaseIterable {
    case psilocybin = "Psilocybin"
    case lsd = "LSD"
    case dmt = "DMT"
    case mdma = "MDMA"
    case ketamine = "Ketamine"
    case ayahuasca = "Ayahuasca"
    case mescaline = "Mescaline"
    case cannabis = "Cannabis"

    /// Display name for UI
    var displayName: String {
        rawValue
    }
}

/// Supported administration methods for psychedelic treatments
enum AdministrationMethod: String, CaseIterable {
    case intravenous = "Intravenous (IV)"
    case intramuscular = "Intramuscular (IM)"
    case oral = "Oral"
    case nasal = "Nasal"
    case other = "Other"

    /// Display name for UI
    var displayName: String {
        rawValue
    }
}

/// Core therapeutic session data model following constitutional principles:
/// - Privacy-First: All data stored locally, no cloud sync
/// - Therapeutic Value-First: Designed for reflection and growth
/// - Offline-First: Works completely without network
@Model
final class TherapeuticSession {
    // MARK: - Core Session Properties

    /// Unique identifier for the session
    var id: UUID

    /// When this session occurred
    var sessionDate: Date

    /// Type of psychedelic therapeutic experience (stored as String)
    var treatmentTypeRawValue: String

    /// Type of psychedelic therapeutic experience (computed from enum)
    var treatmentType: PsychedelicTreatmentType {
        get {
            PsychedelicTreatmentType(rawValue: self.treatmentTypeRawValue) ?? .psilocybin
        }
        set {
            self.treatmentTypeRawValue = newValue.rawValue
        }
    }

    /// Dosage information as a free-form string (e.g., "3.5g dried", "100μg", "50mg")
    var dosage: String

    /// Administration method (stored as String)
    var administrationRawValue: String

    /// Administration method (computed from enum)
    var administration: AdministrationMethod {
        get {
            AdministrationMethod(rawValue: self.administrationRawValue) ?? .oral
        }
        set {
            self.administrationRawValue = newValue.rawValue
        }
    }

    /// User's intention going into the session
    var intention: String

    /// When this record was created
    var createdAt: Date

    /// When this record was last modified
    var updatedAt: Date

    // MARK: - Environment & Setting

    /// Description of the physical environment
    var environmentNotes: String

    /// Music notes or playlist information
    var musicNotes: String

    // MARK: - Mood Tracking

    /// Mood rating before session (1-10 scale)
    var moodBefore: Int

    /// Mood rating after session (1-10 scale)
    var moodAfter: Int

    // MARK: - Reflection

    /// Post-session reflections and insights
    var reflections: String

    /// Reminder date for revisiting reflections
    var reminderDate: Date?

    /// Lifecycle state for this session
    var statusRawValue: String

    var status: SessionLifecycleStatus {
        get { SessionLifecycleStatus(rawValue: self.statusRawValue) ?? .draft }
        set { self.statusRawValue = newValue.rawValue }
    }

    // MARK: - Spotify Integration (Optional)

    /// Spotify playlist URI (optional, from Feature 002)
    var spotifyPlaylistURI: String?

    /// Spotify playlist name for display (optional)
    var spotifyPlaylistName: String?

    /// Spotify playlist cover art URL (optional)
    var spotifyPlaylistImageURL: String?

    // MARK: - Initialization

    init(
        sessionDate: Date = Date(),
        treatmentType: PsychedelicTreatmentType = .psilocybin,
        dosage: String = "",
        administration: AdministrationMethod = .oral,
        intention: String = "",
        environmentNotes: String = "",
        musicNotes: String = "",
        moodBefore: Int = 5,
        moodAfter: Int = 5,
        reflections: String = "",
        status: SessionLifecycleStatus = .draft,
        reminderDate: Date? = nil
    ) {
        self.id = UUID()
        self.sessionDate = sessionDate
        self.treatmentTypeRawValue = treatmentType.rawValue
        self.dosage = dosage
        self.administrationRawValue = administration.rawValue
        self.intention = intention
        self.environmentNotes = environmentNotes
        self.musicNotes = musicNotes
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.reflections = reflections
        self.reminderDate = reminderDate
        self.statusRawValue = status.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()

        // Spotify fields default to nil (optional integration)
        self.spotifyPlaylistURI = nil
        self.spotifyPlaylistName = nil
        self.spotifyPlaylistImageURL = nil
    }
}

// MARK: - Computed Properties

extension TherapeuticSession {
    /// Human-readable session title for UI display
    var displayTitle: String {
        "\(self.treatmentType.displayName) • \(self.sessionDate.formatted(date: .abbreviated, time: .omitted))"
    }

    /// Mood change from before to after session
    var moodChange: Int {
        self.moodAfter - self.moodBefore
    }

    /// Whether this session has Spotify playlist attached
    var hasSpotifyPlaylist: Bool {
        self.spotifyPlaylistURI != nil && !self.spotifyPlaylistURI!.isEmpty
    }

    /// Validation for required fields and psychedelic treatment types
    var isValid: Bool {
        !self.intention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            self.moodBefore >= 1 && self.moodBefore <= 10 &&
            self.moodAfter >= 1 && self.moodAfter <= 10
    }
}

// MARK: - Data Management

extension TherapeuticSession {
    /// Update the modification timestamp
    func markAsUpdated() {
        self.updatedAt = Date()
    }

    /// Clear all Spotify-related data (for disconnection)
    func clearSpotifyData() {
        self.spotifyPlaylistURI = nil
        self.spotifyPlaylistName = nil
        self.spotifyPlaylistImageURL = nil
        self.markAsUpdated()
    }
}

enum SessionLifecycleStatus: String, Codable, CaseIterable {
    case draft
    case needsReflection
    case complete

    var displayName: String {
        switch self {
        case .draft: "Draft"
        case .needsReflection: "Needs Reflection"
        case .complete: "Complete"
        }
    }
}
