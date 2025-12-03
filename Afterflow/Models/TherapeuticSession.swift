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

enum MusicLinkProvider: String, Codable, CaseIterable {
    case spotify
    case youtube
    case soundcloud
    case appleMusic
    case applePodcasts
    case bandcamp
    case tidal
    case linkOnly
    case unknown

    var displayName: String {
        switch self {
        case .spotify: "Spotify"
        case .youtube: "YouTube"
        case .soundcloud: "SoundCloud"
        case .appleMusic: "Apple Music"
        case .applePodcasts: "Apple Podcasts"
        case .bandcamp: "Bandcamp"
        case .tidal: "Tidal"
        case .linkOnly, .unknown: "Playlist Link"
        }
    }

    var supportsOEmbed: Bool {
        switch self {
        case .spotify, .youtube, .soundcloud, .tidal:
            true
        default:
            false
        }
    }

    func oEmbedURL(for canonicalURL: URL) -> URL? {
        guard self.supportsOEmbed else { return nil }
        var components = URLComponents()
        switch self {
        case .spotify:
            components.scheme = "https"
            components.host = "open.spotify.com"
            components.path = "/oembed"
        case .youtube:
            components.scheme = "https"
            components.host = "www.youtube.com"
            components.path = "/oembed"
            components.queryItems = [URLQueryItem(name: "format", value: "json")]
        case .soundcloud:
            components.scheme = "https"
            components.host = "soundcloud.com"
            components.path = "/oembed"
        case .tidal:
            components.scheme = "https"
            components.host = "oembed.tidal.com"
            components.path = "/oembed"
        default:
            return nil
        }
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "url", value: canonicalURL.absoluteString))
        components.queryItems = queryItems
        return components.url
    }

    func fallbackWebURL(for originalURL: URL) -> URL? {
        switch self {
        case .spotify:
            if originalURL.scheme == "spotify" {
                let segments = originalURL.absoluteString.split(separator: ":")
                guard segments.count >= 3 else { return nil }
                let type = segments[1]
                let id = segments[2]
                return URL(string: "https://open.spotify.com/\(type)/\(id)")
            }
            return self.enforceHTTPS(for: originalURL)
        case .youtube:
            if originalURL.host == "youtu.be" {
                let videoID = originalURL.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                guard !videoID.isEmpty else { return nil }
                return URL(string: "https://www.youtube.com/watch?v=\(videoID)")
            }
            return self.enforceHTTPS(for: originalURL)
        case .soundcloud, .appleMusic, .applePodcasts, .bandcamp, .tidal, .linkOnly, .unknown:
            return self.enforceHTTPS(for: originalURL)
        }
    }

    private func enforceHTTPS(for url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        if components.scheme == nil || components.scheme == "http" { components.scheme = "https" }
        return components.url
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

    // MARK: - Music Link Integration (Optional)

    /// Original playlist URL supplied by the user (could be app-specific scheme)
    var musicLinkURL: String?

    /// Canonical HTTPS URL used for previews/fallbacks
    var musicLinkWebURL: String?

    /// Playlist title returned by metadata service
    var musicLinkTitle: String?

    /// Playlist author/curator name (optional)
    var musicLinkAuthorName: String?

    /// Playlist artwork/thumbnail URL
    var musicLinkArtworkURL: String?

    /// Link duration (seconds) when available from oEmbed
    var musicLinkDurationSeconds: Int?

    /// Underlying provider raw value
    var musicLinkProviderRawValue: String?

    // MARK: - Initialization

    init(
        sessionDate: Date = Date(),
        treatmentType: PsychedelicTreatmentType = .psilocybin,
        administration: AdministrationMethod = .oral,
        intention: String = "",
        moodBefore: Int = 5,
        moodAfter: Int = 5,
        reflections: String = "",
        reminderDate: Date? = nil
    ) {
        self.id = UUID()
        self.sessionDate = sessionDate
        self.treatmentTypeRawValue = treatmentType.rawValue
        self.administrationRawValue = administration.rawValue
        self.intention = intention
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.reflections = reflections
        self.reminderDate = reminderDate
        self.createdAt = Date()
        self.updatedAt = Date()

        self.musicLinkURL = nil
        self.musicLinkWebURL = nil
        self.musicLinkTitle = nil
        self.musicLinkAuthorName = nil
        self.musicLinkArtworkURL = nil
        self.musicLinkDurationSeconds = nil
        self.musicLinkProviderRawValue = nil
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

    /// Whether this session has a stored playlist link
    var hasMusicLink: Bool {
        guard let url = self.musicLinkURL ?? self.musicLinkWebURL else { return false }
        return !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var musicLinkProvider: MusicLinkProvider {
        get {
            guard let raw = self.musicLinkProviderRawValue else { return .unknown }
            return MusicLinkProvider(rawValue: raw) ?? .unknown
        }
        set {
            self.musicLinkProviderRawValue = newValue == .unknown ? nil : newValue.rawValue
        }
    }

    var preferredOpenURL: URL? {
        if let original = self.musicLinkURL, let url = URL(string: original) {
            return url
        }
        if let web = self.musicLinkWebURL, let url = URL(string: web) {
            return url
        }
        return nil
    }

    /// Display string for reminder timestamp
    var reminderDisplayText: String? {
        guard let reminderDate else { return nil }
        if reminderDate < Date() {
            return nil
        }
        return reminderDate.formatted(date: .abbreviated, time: .shortened)
    }

    var reminderRelativeDescription: String? {
        guard let reminderDate else { return nil }
        if reminderDate < Date() {
            return nil
        }
        let calendar = Calendar.current
        let timeString = reminderDate.formatted(date: .omitted, time: .shortened)
        if calendar.isDateInToday(reminderDate) {
            return "Today \(timeString)"
        }
        if calendar.isDateInTomorrow(reminderDate) {
            return "Tomorrow \(timeString)"
        }
        return reminderDate.formatted(date: .abbreviated, time: .shortened)
    }

    /// Validation for required fields and psychedelic treatment types
    var isValid: Bool {
        !self.intention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            self.moodBefore >= 1 && self.moodBefore <= 10 &&
            self.moodAfter >= 1 && self.moodAfter <= 10
    }

    /// Derived lifecycle status based on required fields and reflections
    var status: SessionLifecycleStatus {
        let hasCoreFields = !self.intention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            (1 ... 10).contains(self.moodBefore)
        guard hasCoreFields else { return .draft }

        let hasReflections = !self.reflections.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasReflections ? .complete : .needsReflection
    }
}

// MARK: - Data Management

extension TherapeuticSession {
    /// Update the modification timestamp
    func markAsUpdated() {
        self.updatedAt = Date()
    }

    /// Clear all music link metadata
    func clearMusicLinkData() {
        self.musicLinkURL = nil
        self.musicLinkWebURL = nil
        self.musicLinkTitle = nil
        self.musicLinkAuthorName = nil
        self.musicLinkArtworkURL = nil
        self.musicLinkDurationSeconds = nil
        self.musicLinkProviderRawValue = nil
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
        case .needsReflection: "Reflect"
        case .complete: "Complete"
        }
    }
}
