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
            reflections: """
            **Initial Experience**: The music created a profound sense of safety and openness.

            *Key Insights*:
            • Felt deep connection to childhood memories
            • Recognized patterns in relationships
            • Experienced release of old grief

            The journey was **transformative** and I feel ready to integrate these insights.
            """,
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
            reflections: """
            *Post-session reflections*

            The calming playlist helped me stay grounded during challenging moments. **Three major realizations**:

            1. Self-compassion is not selfish
            2. My inner critic's voice is learned, not inherent
            3. I deserve the same kindness I give others

            Looking forward to continuing this integration work.
            """,
            reminderDate: nil
        )
        linkOnly.musicLinkURL = "https://music.apple.com/us/playlist/calm/pl.u-123"
        linkOnly.musicLinkWebURL = "https://music.apple.com/us/playlist/calm/pl.u-123"
        linkOnly.musicLinkTitle = "Calm"
        linkOnly.musicLinkAuthorName = "Apple Music"
        linkOnly.musicLinkProvider = .appleMusic
        seeds.append(linkOnly)

        let treatments = PsychedelicTreatmentType.allCases
        let reflectionTemplates = [
            """
            **Physical sensations**: Warmth, openness, gentle waves of emotion.

            *Emotional processing*:
            • Released tension around family dynamics
            • Found compassion for my younger self
            • Recognized recurring thought patterns
            """,
            """
            *Integration notes from today*

            The session revealed **important insights** about my relationship with control and trust.

            1. Letting go doesn't mean giving up
            2. Vulnerability can be a strength
            3. I don't have to have all the answers
            """,
            """
            **Breakthrough moment**: Connected deeply with a sense of purpose and meaning.

            • Felt universal love and interconnection
            • Experienced ego dissolution
            • Recognized the impermanence of suffering

            *This was profound.* I need time to integrate.
            """,
            "Simple reflection without formatting - just observing and being present with the experience.",
            """
            **What emerged**:

            *Recurring themes*: forgiveness, acceptance, self-love

            I'm beginning to understand that healing isn't linear. Some days are harder, and that's okay.
            """
        ]

        for i in 1 ... 18 {
            let hasReflection = i % 2 == 0
            let reflection = hasReflection ? reflectionTemplates[i % reflectionTemplates.count] : ""

            let session = TherapeuticSession(
                sessionDate: now.addingTimeInterval(TimeInterval(-i * 86400)),
                treatmentType: treatments[i % treatments.count],
                administration: .oral,
                intention: "Seeded Session \(i)",
                moodBefore: (i % 10) + 1,
                moodAfter: ((i + 2) % 10) + 1,
                reflections: reflection,
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
