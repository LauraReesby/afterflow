@testable import Afterflow
import Foundation

enum SessionFixtureFactory {
    static func makeSessions(count: Int, referenceDate: Date = Date()) -> [TherapeuticSession] {
        var sessions: [TherapeuticSession] = []
        let treatments = PsychedelicTreatmentType.allCases

        for index in 0 ..< count {
            let session = TherapeuticSession(
                sessionDate: referenceDate.addingTimeInterval(TimeInterval(-index * 86400)),
                treatmentType: treatments[index % treatments.count],
                administration: .oral,
                intention: "Fixture Session \(index)",
                moodBefore: (index % 10) + 1,
                moodAfter: ((index + 3) % 10) + 1,
                reflections: index.isMultiple(of: 2) ? "Short reflection \(index)" : "",
                reminderDate: index.isMultiple(of: 4) ? referenceDate
                    .addingTimeInterval(TimeInterval(900 * (index + 1))) : nil
            )
            sessions.append(session)
        }

        return sessions
    }

    static func makeSeedSessions(referenceDate: Date = Date()) -> [TherapeuticSession] {
        SeedDataFactory.makeSeedSessions(referenceDate: referenceDate)
    }

    static func makeSessionWithReminder(
        referenceDate: Date = Date(),
        reminderOffset: TimeInterval = 3600
    ) -> TherapeuticSession {
        TherapeuticSession(
            sessionDate: referenceDate,
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Session with reminder",
            moodBefore: 5,
            moodAfter: 8,
            reflections: "Reflection text",
            reminderDate: referenceDate.addingTimeInterval(reminderOffset)
        )
    }

    static func makeSessionsForCalendar(
        monthCount: Int = 3,
        sessionsPerMonth: Int = 5,
        referenceDate: Date = Date()
    ) -> [TherapeuticSession] {
        var sessions: [TherapeuticSession] = []
        let calendar = Calendar.current

        for monthOffset in 0 ..< monthCount {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: referenceDate) else {
                continue
            }

            for dayOffset in 0 ..< sessionsPerMonth {
                guard let sessionDate = calendar.date(byAdding: .day, value: dayOffset * 5, to: monthDate) else {
                    continue
                }

                let session = TherapeuticSession(
                    sessionDate: sessionDate,
                    treatmentType: PsychedelicTreatmentType
                        .allCases[dayOffset % PsychedelicTreatmentType.allCases.count],
                    administration: .oral,
                    intention: "Calendar session \(monthOffset)-\(dayOffset)",
                    moodBefore: (dayOffset % 10) + 1,
                    moodAfter: ((dayOffset + 3) % 10) + 1,
                    reflections: dayOffset.isMultiple(of: 2) ? "Reflection \(dayOffset)" : "",
                    reminderDate: nil
                )
                sessions.append(session)
            }
        }

        return sessions
    }

    static func makeSessionWithMusicLink(
        provider: String = "spotify",
        referenceDate: Date = Date()
    ) -> TherapeuticSession {
        let musicURL = switch provider.lowercased() {
        case "spotify":
            "https://open.spotify.com/playlist/37i9dQZF1DX4dyzvuaRJ0n"
        case "youtube":
            "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        case "apple":
            "https://music.apple.com/us/playlist/chill-vibes/pl.u-EdAVlG2CDWBXP4"
        case "soundcloud":
            "https://soundcloud.com/user/track"
        case "tidal":
            "https://tidal.com/browse/playlist/123456"
        default:
            "https://example.com/music"
        }

        let session = TherapeuticSession(
            sessionDate: referenceDate,
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Session with \(provider) music link",
            moodBefore: 5,
            moodAfter: 8,
            reflections: "",
            reminderDate: nil
        )

        session.musicLinkURL = musicURL
        return session
    }

    static func makeSessionsWithEdgeCases() -> [TherapeuticSession] {
        var sessions: [TherapeuticSession] = []

        sessions.append(TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "",
            moodBefore: 1,
            moodAfter: 10,
            reflections: "",
            reminderDate: nil
        ))

        let longText = String(repeating: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. ", count: 100)
        sessions.append(TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .lsd,
            administration: .oral,
            intention: longText,
            moodBefore: 5,
            moodAfter: 8,
            reflections: longText,
            reminderDate: nil
        ))

        sessions.append(TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .mdma,
            administration: .oral,
            intention: "Explore creativity 🌈✨ with émotions françaises and 日本語",
            moodBefore: 4,
            moodAfter: 9,
            reflections: "Felt peaceful 🧘‍♀️ and connected 🌍 to everything",
            reminderDate: nil
        ))

        sessions.append(TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .ketamine,
            administration: .oral,
            intention: "Intention with \"quotes\", commas, and\nnewlines",
            moodBefore: 3,
            moodAfter: 7,
            reflections: "Reflection with special chars: <>&'\"",
            reminderDate: nil
        ))

        sessions.append(TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .ayahuasca,
            administration: .oral,
            intention: "Minimum mood before, maximum mood after",
            moodBefore: 1,
            moodAfter: 10,
            reflections: "",
            reminderDate: nil
        ))

        return sessions
    }
}
