@testable import Afterflow
import SwiftData
import XCTest

@MainActor
final class ReflectionQueueTests: XCTestCase {
    private let queueKey = "afterflow.reflection.queue"

    override func setUp() async throws {
        UserDefaults.standard.removeObject(forKey: self.queueKey)
    }

    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: self.queueKey)
    }

    func testAddReflectionPersistsWhenSessionExists() async throws {
        let container = try ModelContainer(
            for: TherapeuticSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Persist",
            moodBefore: 5,
            moodAfter: 6
        )
        container.mainContext.insert(session)

        let queue = ReflectionQueue(modelContext: container.mainContext)
        try await queue.addReflection(sessionID: session.id, text: "Saved from test")

        let fetched = try container.mainContext.fetch(FetchDescriptor<TherapeuticSession>()).first
        XCTAssertTrue(fetched?.reflections.contains("Saved from test") ?? false)
        XCTAssertEqual(queue.queuedCount, 0)
    }

    func testQueuesWhenSessionMissing() async throws {
        let container = try ModelContainer(
            for: TherapeuticSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let queue = ReflectionQueue(modelContext: container.mainContext)

        try await queue.addReflection(sessionID: UUID(), text: "Queued reflection")
        XCTAssertEqual(queue.queuedCount, 1)
    }

    func testReplayQueuedReflections() async throws {
        let container = try ModelContainer(
            for: TherapeuticSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let queue = ReflectionQueue(modelContext: container.mainContext)

        let targetID = UUID()
        try await queue.addReflection(sessionID: targetID, text: "Replay me")
        XCTAssertEqual(queue.queuedCount, 1)

        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .ketamine,
            administration: .intravenous,
            intention: "Target",
            moodBefore: 5,
            moodAfter: 5
        )
        session.id = targetID
        container.mainContext.insert(session)

        await queue.replayQueuedReflections()

        let fetched = try container.mainContext.fetch(FetchDescriptor<TherapeuticSession>()).first
        XCTAssertTrue(fetched?.reflections.contains("Replay me") ?? false)
        XCTAssertEqual(queue.queuedCount, 0)
    }
}
