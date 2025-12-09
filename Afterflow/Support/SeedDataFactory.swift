import Foundation

enum SeedDataFactory {
    static func makeSeedSessions(referenceDate: Date = Date()) -> [TherapeuticSession] {
        let now = referenceDate
        var seeds: [TherapeuticSession] = []

        let tier1 = TherapeuticSession(
            sessionDate: now,
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Tier1 Music Session",
            moodBefore: 5,
            moodAfter: 6,
            reflections: "Seeded tier1 metadata",
            reminderDate: nil
        )
        tier1.musicLinkURL = "https://open.spotify.com/playlist/37i9dQZF1DX4WYpdgoIcn6"
        tier1.musicLinkWebURL = "https://open.spotify.com/playlist/37i9dQZF1DX4WYpdgoIcn6"
        tier1.musicLinkTitle = "Lo-Fi Focus"
        tier1.musicLinkAuthorName = "Lo-Fi Collective"
        tier1.musicLinkDurationSeconds = 3600
        tier1.musicLinkProvider = .spotify
        seeds.append(tier1)

        let linkOnly = TherapeuticSession(
            sessionDate: now.addingTimeInterval(-3600),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Link Only Music Session",
            moodBefore: 5,
            moodAfter: 6,
            reflections: "Seeded link-only metadata",
            reminderDate: nil
        )
        linkOnly.musicLinkURL = "https://music.apple.com/us/playlist/calm/pl.u-123"
        linkOnly.musicLinkWebURL = "https://music.apple.com/us/playlist/calm/pl.u-123"
        linkOnly.musicLinkTitle = "Calm"
        linkOnly.musicLinkAuthorName = "Apple Music"
        linkOnly.musicLinkProvider = .appleMusic
        seeds.append(linkOnly)

        let treatments = PsychedelicTreatmentType.allCases
        for i in 1 ... 18 {
            let session = TherapeuticSession(
                sessionDate: now.addingTimeInterval(TimeInterval(-i * 86400)),
                treatmentType: treatments[i % treatments.count],
                administration: .oral,
                intention: "Seeded Session \(i)",
                moodBefore: (i % 10) + 1,
                moodAfter: ((i + 2) % 10) + 1,
                reflections: i % 2 == 0 ? "Reflection note \(i)" : "",
                reminderDate: i % 3 == 0 ? now.addingTimeInterval(TimeInterval(i * 600)) : nil
            )
            if i % 4 == 0 {
                session.musicLinkURL = "https://open.spotify.com/playlist/seed-\(i)"
                session.musicLinkProvider = .spotify
            }
            seeds.append(session)
        }

        return seeds
    }
}
