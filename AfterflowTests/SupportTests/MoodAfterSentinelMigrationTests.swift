@testable import Afterflow
import Foundation
import SwiftData
import Testing

@MainActor
struct MoodAfterSentinelMigrationTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: TherapeuticSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "test.moodAfterMigration.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test("Sentinel rows (5, no reflections) are cleared to nil") func clearsSentinelRows() throws {
        let container = try self.makeContainer()
        let context = container.mainContext

        let sentinel = TherapeuticSession(intention: "Old default", moodBefore: 4, moodAfter: 5)
        let whitespaceSentinel = TherapeuticSession(intention: "Whitespace", moodBefore: 4, moodAfter: 5)
        whitespaceSentinel.reflections = "  \n "
        context.insert(sentinel)
        context.insert(whitespaceSentinel)
        try context.save()

        let cleared = try MoodAfterSentinelMigration.clearSentinels(in: context)

        #expect(cleared == 2)
        #expect(sentinel.moodAfter == nil)
        #expect(whitespaceSentinel.moodAfter == nil)
    }

    @Test("Genuine after-moods are preserved") func preservesGenuineAfterMoods() throws {
        let container = try self.makeContainer()
        let context = container.mainContext

        let genuineFive = TherapeuticSession(intention: "Real five", moodBefore: 4, moodAfter: 5)
        genuineFive.reflections = "A recorded after-mood of exactly five."
        let nonFive = TherapeuticSession(intention: "No reflections", moodBefore: 4, moodAfter: 7)
        let alreadyNil = TherapeuticSession(intention: "Never recorded", moodBefore: 4, moodAfter: nil)
        context.insert(genuineFive)
        context.insert(nonFive)
        context.insert(alreadyNil)
        try context.save()

        let cleared = try MoodAfterSentinelMigration.clearSentinels(in: context)

        #expect(cleared == 0)
        #expect(genuineFive.moodAfter == 5)
        #expect(nonFive.moodAfter == 7)
        #expect(alreadyNil.moodAfter == nil)
    }

    @Test("runIfNeeded executes once and sets the flag") func runsOnceAndSetsFlag() throws {
        let container = try self.makeContainer()
        let context = container.mainContext
        let defaults = self.makeDefaults()

        let sentinel = TherapeuticSession(intention: "First run", moodBefore: 4, moodAfter: 5)
        context.insert(sentinel)
        try context.save()

        let firstRun = MoodAfterSentinelMigration.runIfNeeded(context: context, defaults: defaults)
        #expect(firstRun == 1)
        #expect(sentinel.moodAfter == nil)
        #expect(defaults.bool(forKey: MoodAfterSentinelMigration.defaultsKey))

        // A sentinel-shaped row created after the migration must NOT be touched
        // by later launches — the cleanup is strictly one-time.
        let postMigration = TherapeuticSession(intention: "Post-migration", moodBefore: 4, moodAfter: 5)
        context.insert(postMigration)
        try context.save()

        let secondRun = MoodAfterSentinelMigration.runIfNeeded(context: context, defaults: defaults)
        #expect(secondRun == 0)
        #expect(postMigration.moodAfter == 5)
    }
}
