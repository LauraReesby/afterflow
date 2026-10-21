@testable import Afterflow
import Foundation
import Testing

@MainActor
struct BackupServiceTests {
    private let service = BackupService()

    @Test("Round trip preserves every field with exact dates") func roundTripIsFieldForFieldExact() throws {
        let sessions = [
            BackupTestHelpers.makeFullSession(index: 0),
            BackupTestHelpers.makeFullSession(index: 1),
            BackupTestHelpers.makeMinimalSession()
        ]
        let exportedAt = Date(timeIntervalSinceReferenceDate: 795_000_000.678_9)

        let data = try self.service.encode(sessions: sessions, exportedAt: exportedAt)
        let decoded = try self.service.decode(data)

        #expect(decoded.formatVersion == AfterflowBackup.currentFormatVersion)
        #expect(decoded.exportedAt == exportedAt)
        #expect(decoded.sessions.count == sessions.count)
        for (record, session) in zip(decoded.sessions, sessions) {
            #expect(record == SessionBackupRecord(session: session))
            #expect(record.sessionDate == session.sessionDate)
            #expect(record.createdAt == session.createdAt)
            #expect(record.updatedAt == session.updatedAt)
            #expect(record.reminderDate == session.reminderDate)
        }
    }

    @Test("Round trip keeps nil optionals nil") func roundTripKeepsNilOptionals() throws {
        let session = BackupTestHelpers.makeMinimalSession()

        let decoded = try self.service.decode(self.service.encode(sessions: [session]))

        let record = try #require(decoded.sessions.first)
        #expect(record.moodAfter == nil)
        #expect(record.reminderDate == nil)
        #expect(record.musicLinkURL == nil)
        #expect(record.musicLinkProviderRawValue == nil)
        #expect(record == SessionBackupRecord(session: session))
    }

    @Test("Unknown enum raw values survive a round trip") func unknownRawValuesSurvive() throws {
        let session = BackupTestHelpers.makeFullSession()
        session.treatmentTypeRawValue = "FutureCompound"
        session.administrationRawValue = "Telepathic"
        session.musicLinkProviderRawValue = "futureProvider"

        let decoded = try self.service.decode(self.service.encode(sessions: [session]))

        let record = try #require(decoded.sessions.first)
        #expect(record.treatmentTypeRawValue == "FutureCompound")
        #expect(record.administrationRawValue == "Telepathic")
        #expect(record.musicLinkProviderRawValue == "futureProvider")
    }

    @Test("Backup includes every session passed in") func backupIncludesAllSessions() {
        let sessions = SessionFixtureFactory.makeSessions(count: 25)

        let backup = self.service.makeBackup(sessions: sessions)

        #expect(backup.sessions.count == 25)
        #expect(Set(backup.sessions.map(\.id)) == Set(sessions.map(\.id)))
    }

    @Test("Dates are written as raw numbers, not ISO strings") func datesAreRawDoubles() throws {
        let session = BackupTestHelpers.makeFullSession()

        let data = try self.service.encode(sessions: [session])

        let root = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let records = try #require(root["sessions"] as? [[String: Any]])
        let first = try #require(records.first)
        let sessionDate = try #require(first["sessionDate"] as? Double)
        #expect(sessionDate == session.sessionDate.timeIntervalSinceReferenceDate)
        #expect(root["exportedAt"] is Double)
    }

    @Test("Encoding is stable for identical input") func encodingIsStable() throws {
        let sessions = [BackupTestHelpers.makeFullSession(), BackupTestHelpers.makeMinimalSession()]
        let exportedAt = Date(timeIntervalSinceReferenceDate: 795_000_000)

        let first = try self.service.encode(sessions: sessions, exportedAt: exportedAt)
        let second = try self.service.encode(sessions: sessions, exportedAt: exportedAt)

        #expect(first == second)
    }

    @Test("Newer format version is rejected with a typed error") func newerVersionIsRejected() throws {
        let future = AfterflowBackup(
            formatVersion: AfterflowBackup.currentFormatVersion + 1,
            exportedAt: Date(),
            appVersion: "99.0",
            sessions: []
        )
        let data = try self.service.encode(future)

        #expect(throws: BackupError.unsupportedVersion(AfterflowBackup.currentFormatVersion + 1)) {
            try self.service.decode(data)
        }
    }

    @Test("Newer version is reported even if the layout changed") func newerVersionWithUnknownLayout() throws {
        let data = Data(#"{"formatVersion": 7, "sessions": "not-an-array"}"#.utf8)

        #expect(throws: BackupError.unsupportedVersion(7)) {
            try self.service.decode(data)
        }
    }

    @Test("Garbage data is rejected with a typed error") func garbageIsRejected() {
        let inputs = [
            Data(),
            Data("not json at all".utf8),
            Data("{}".utf8),
            Data("[1, 2, 3]".utf8),
            Data(#"{"formatVersion": 0, "exportedAt": 0, "sessions": []}"#.utf8),
            Data(#"{"formatVersion": 1, "exportedAt": 0, "sessions": [{"id": "nope"}]}"#.utf8)
        ]

        for input in inputs {
            #expect(throws: BackupError.invalidFile) {
                try self.service.decode(input)
            }
        }
    }

    @Test("Error messages never echo file contents") func errorMessagesOmitContents() throws {
        let session = BackupTestHelpers.makeFullSession()
        session.intention = "SECRET-INTENTION"
        let data = try self.service.encode(sessions: [session])
        let truncated = data.prefix(data.count / 2)

        do {
            _ = try self.service.decode(Data(truncated))
            Issue.record("Truncated backup should not decode")
        } catch {
            #expect(!error.localizedDescription.contains("SECRET"))
        }
        #expect(BackupError.unsupportedVersion(2).localizedDescription.contains("newer version of Afterflow"))
    }

    @Test("Filename uses the backup date without an extension") func filenameUsesDate() throws {
        let date = try #require(Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 1, hour: 12)))

        #expect(BackupService.filename(for: date) == "Afterflow-Backup-2024-12-01")
    }
}
