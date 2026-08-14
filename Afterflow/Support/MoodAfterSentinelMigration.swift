import Foundation
import SwiftData

/// One-time disambiguation for data written before `moodAfter` became optional:
/// the old schema defaulted it to 5, so 5-with-no-reflections meant "not
/// recorded". Applies that reading once, then the sentinel never matters again.
/// (A legacy genuine after-mood of exactly 5 with no reflection text is
/// indistinguishable from the default and is reset — unrecoverable by design.)
@MainActor
enum MoodAfterSentinelMigration {
    static let defaultsKey = "afterflow.migration.moodAfterSentinelCleared"

    /// Runs the cleanup once per install, gated by `defaultsKey`. On failure the
    /// flag stays unset so the cleanup retries on the next launch.
    /// Returns the number of sessions cleared (0 when already run or nothing matched).
    @discardableResult static func runIfNeeded(context: ModelContext, defaults: UserDefaults = .standard) -> Int {
        guard !defaults.bool(forKey: self.defaultsKey) else { return 0 }

        do {
            let cleared = try self.clearSentinels(in: context)
            defaults.set(true, forKey: self.defaultsKey)
            return cleared
        } catch {
            return 0
        }
    }

    /// The disambiguation itself: sessions whose after-mood is exactly the old
    /// default (5) with no reflection text are treated as "not recorded".
    @discardableResult static func clearSentinels(in context: ModelContext) throws -> Int {
        let sessions = try context.fetch(FetchDescriptor<TherapeuticSession>())
        var cleared = 0
        for session in sessions where session.moodAfter == 5
            && session.reflections.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            session.moodAfter = nil
            cleared += 1
        }
        if context.hasChanges {
            try context.save()
        }
        return cleared
    }
}
