@testable import Afterflow
import Foundation
import SwiftData
import Testing

@MainActor
struct PersistenceControllerTests {
    // MARK: - Fixtures

    private func makeSandbox() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "PersistenceControllerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeController(in sandbox: URL) -> PersistenceController {
        PersistenceController(
            storeURL: sandbox.appending(path: "default.store"),
            recoveryRootURL: sandbox.appending(path: "Recovered"),
            temporaryRootURL: sandbox.appending(path: "tmp")
        )
    }

    private func sessionCount(in container: ModelContainer) throws -> Int {
        try container.mainContext.fetch(FetchDescriptor<TherapeuticSession>()).count
    }

    private func write(_ text: String, to url: URL) throws -> Data {
        let data = Data(text.utf8)
        try data.write(to: url)
        return data
    }

    // MARK: - Opening

    @Test("A fresh on-disk store opens and persists across containers") func opensAndPersistsOnDisk() throws {
        let sandbox = try self.makeSandbox()
        defer { try? FileManager.default.removeItem(at: sandbox) }
        let controller = self.makeController(in: sandbox)

        do {
            let container = try controller.open().get()
            container.mainContext.insert(TherapeuticSession(intention: "Persisted", moodBefore: 4, moodAfter: 7))
            try container.mainContext.save()
        }

        let reopened = try controller.open().get()
        let sessions = try reopened.mainContext.fetch(FetchDescriptor<TherapeuticSession>())
        #expect(sessions.count == 1)
        #expect(sessions.first?.moodAfter == 7)
    }

    @Test("A store written without a migration plan opens through the versioned schema")
    func opensLegacyUnversionedStore() throws {
        let sandbox = try self.makeSandbox()
        defer { try? FileManager.default.removeItem(at: sandbox) }
        let controller = self.makeController(in: sandbox)

        do {
            let schema = Schema([TherapeuticSession.self])
            let legacy = try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, url: controller.storeURL)]
            )
            legacy.mainContext.insert(TherapeuticSession(intention: "Legacy", moodBefore: 3))
            try legacy.mainContext.save()
        }

        let container = try controller.open().get()
        #expect(try self.sessionCount(in: container) == 1)
    }

    @Test("A store file of garbage bytes yields a failure result and is left untouched")
    func garbageStoreFailsWithoutTouchingFile() throws {
        let sandbox = try self.makeSandbox()
        defer { try? FileManager.default.removeItem(at: sandbox) }
        let controller = self.makeController(in: sandbox)
        let garbage = try self.write(
            String(repeating: "not a sqlite database ", count: 512),
            to: controller.storeURL
        )

        switch controller.open() {
        case .success:
            Issue.record("Expected opening a garbage store to fail")
        case .failure:
            break
        }
        #expect(try Data(contentsOf: controller.storeURL) == garbage)
    }

    @Test("In-memory mode opens without creating store files") func inMemoryCreatesNoFiles() throws {
        let sandbox = try self.makeSandbox()
        defer { try? FileManager.default.removeItem(at: sandbox) }
        let controller = PersistenceController(
            storeURL: sandbox.appending(path: "default.store"),
            isStoredInMemoryOnly: true
        )

        let container = try controller.open().get()
        #expect(try self.sessionCount(in: container) == 0)
        #expect(controller.existingStoreFileURLs.isEmpty)
    }

    @Test("The default store location matches SwiftData's implicit one") func defaultStoreLocation() {
        let implicit = URL.applicationSupportDirectory.appending(path: "default.store")
        #expect(PersistenceController.defaultStoreURL == implicit)
    }

    // MARK: - Save a copy

    @Test("Export copy includes the store and wal, skips the missing shm, and leaves originals")
    func exportCopySkipsMissingFiles() throws {
        let sandbox = try self.makeSandbox()
        defer { try? FileManager.default.removeItem(at: sandbox) }
        let controller = self.makeController(in: sandbox)
        let storeBytes = try self.write("store", to: controller.storeURL)
        let walBytes = try self.write("wal", to: controller.storeFileURLs[1])

        let copies = try controller.makeExportCopy()

        #expect(copies.map(\.lastPathComponent) == ["default.store", "default.store-wal"])
        #expect(try Data(contentsOf: copies[0]) == storeBytes)
        #expect(try Data(contentsOf: copies[1]) == walBytes)
        #expect(controller.existingStoreFileURLs.count == 2)
    }

    @Test("A new export copy replaces the previous one") func exportCopyReplacesPrevious() throws {
        let sandbox = try self.makeSandbox()
        defer { try? FileManager.default.removeItem(at: sandbox) }
        let controller = self.makeController(in: sandbox)
        _ = try self.write("store", to: controller.storeURL)
        _ = try self.write("shm", to: controller.storeFileURLs[2])
        #expect(try controller.makeExportCopy().count == 2)

        try FileManager.default.removeItem(at: controller.storeFileURLs[2])
        let copies = try controller.makeExportCopy()

        #expect(copies.map(\.lastPathComponent) == ["default.store"])
        controller.removeExportCopy()
        #expect(!FileManager.default.fileExists(atPath: copies[0].path))
    }

    // MARK: - Start fresh (quarantine)

    @Test("Quarantine moves every store file into a timestamped folder, byte for byte")
    func quarantineMovesFiles() throws {
        let sandbox = try self.makeSandbox()
        defer { try? FileManager.default.removeItem(at: sandbox) }
        let controller = self.makeController(in: sandbox)
        let originals = controller.storeFileURLs
        let payloads = try zip(originals, ["store", "wal", "shm"]).map { try self.write($1, to: $0) }

        let folder = try controller.quarantineStoreFiles(at: TestHelpers.fixedDate())

        #expect(folder.deletingLastPathComponent().lastPathComponent == "Recovered")
        #expect(folder.lastPathComponent == "2024-12-01T12-00-00Z")
        for (original, payload) in zip(originals, payloads) {
            #expect(!FileManager.default.fileExists(atPath: original.path))
            let moved = folder.appending(path: original.lastPathComponent)
            #expect(try Data(contentsOf: moved) == payload)
        }
    }

    @Test("Quarantine moves only files that exist and never reuses a recovered folder")
    func quarantineSkipsMissingAndUsesUniqueFolders() throws {
        let sandbox = try self.makeSandbox()
        defer { try? FileManager.default.removeItem(at: sandbox) }
        let controller = self.makeController(in: sandbox)
        let date = TestHelpers.fixedDate()

        _ = try self.write("first", to: controller.storeURL)
        let first = try controller.quarantineStoreFiles(at: date)
        _ = try self.write("second", to: controller.storeURL)
        let second = try controller.quarantineStoreFiles(at: date)

        #expect(first != second)
        #expect(try Data(contentsOf: first.appending(path: "default.store")) == Data("first".utf8))
        #expect(try Data(contentsOf: second.appending(path: "default.store")) == Data("second".utf8))
        #expect(!FileManager.default.fileExists(atPath: first.appending(path: "default.store-wal").path))
    }

    @Test("After quarantine a new empty store opens and the old data is still readable")
    func quarantineThenOpenKeepsOldData() throws {
        let sandbox = try self.makeSandbox()
        defer { try? FileManager.default.removeItem(at: sandbox) }
        let controller = self.makeController(in: sandbox)

        do {
            let container = try controller.open().get()
            container.mainContext.insert(TherapeuticSession(intention: "Keep me", moodBefore: 6))
            try container.mainContext.save()
        }

        let folder = try controller.quarantineStoreFiles()
        let fresh = try controller.open().get()
        #expect(try self.sessionCount(in: fresh) == 0)

        let recovered = PersistenceController(storeURL: folder.appending(path: "default.store"))
        let old = try recovered.open().get()
        #expect(try self.sessionCount(in: old) == 1)
    }
}
