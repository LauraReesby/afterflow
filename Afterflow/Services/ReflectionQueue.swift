import Combine
import Foundation
import SwiftData

@MainActor
final class ReflectionQueue: ObservableObject {
    let objectWillChange = PassthroughSubject<Void, Never>()

    struct QueuedReflection: Codable, Identifiable {
        let id: UUID
        let sessionID: UUID
        let text: String
        let timestamp: Date
        let createdAt: Date

        init(sessionID: UUID, text: String, timestamp: Date = Date(), id: UUID = UUID(), createdAt: Date = Date()) {
            self.id = id
            self.sessionID = sessionID
            self.text = text
            self.timestamp = timestamp
            self.createdAt = createdAt
        }
    }

    enum ReflectionError: Error, LocalizedError {
        case persistenceFailed(String)
        case queueFull(Int)
        case sessionNotFound(UUID)

        var errorDescription: String? {
            switch self {
            case let .persistenceFailed(reason):
                "Failed to save reflection: \(reason)"
            case let .queueFull(maxSize):
                "Reflection queue full (max \(maxSize) items)"
            case let .sessionNotFound(id):
                "Session not found: \(id)"
            }
        }
    }

    static let maxQueueSize = 100
    static let queueWarningThreshold = 90
    static let confirmationDisplayDuration: Duration = .seconds(3)

    private static let queueStorageKey = "afterflow.reflection.queue"

    @Published private(set) var queuedCount: Int = 0

    @Published var recentConfirmations: [String] = []

    @Published var queueNearingCapacity: Bool = false

    private let modelContext: ModelContext
    private var confirmationTasks: [Task<Void, Never>] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.loadQueue()
    }

    deinit {
        for task in confirmationTasks {
            task.cancel()
        }
    }

    func addReflection(sessionID: UUID, text: String, timestamp: Date = Date()) async throws {
        do {
            try await self.persistReflectionImmediately(sessionID: sessionID, text: text, timestamp: timestamp)
            await self.addConfirmation("Reflection saved")
        } catch {
            try self.queueReflection(sessionID: sessionID, text: text, timestamp: timestamp)
            await self.addConfirmation("Reflection queued (will sync when app opens)")
        }
    }

    private func persistReflectionImmediately(sessionID: UUID, text: String, timestamp: Date) async throws {
        let descriptor = FetchDescriptor<TherapeuticSession>(
            predicate: #Predicate { $0.id == sessionID }
        )

        guard let session = try modelContext.fetch(descriptor).first else {
            throw ReflectionError.sessionNotFound(sessionID)
        }

        session.addReflection(text, timestamp: timestamp)

        do {
            try self.modelContext.save()
        } catch {
            throw ReflectionError.persistenceFailed(error.localizedDescription)
        }
    }

    private func queueReflection(sessionID: UUID, text: String, timestamp: Date) throws {
        var queue = self.loadQueueFromStorage()

        guard queue.count < Self.maxQueueSize else {
            throw ReflectionError.queueFull(Self.maxQueueSize)
        }

        let queuedReflection = QueuedReflection(sessionID: sessionID, text: text, timestamp: timestamp)
        queue.append(queuedReflection)

        self.saveQueueToStorage(queue)
        self.queuedCount = queue.count
        self.queueNearingCapacity = queue.count >= Self.queueWarningThreshold
    }

    func replayQueuedReflections() async {
        let queue = self.loadQueueFromStorage()
        guard !queue.isEmpty else { return }

        var successfullyReplayed: [UUID] = []
        var confirmationMessages: [String] = []

        for queuedReflection in queue {
            do {
                try await self.persistReflectionImmediately(
                    sessionID: queuedReflection.sessionID,
                    text: queuedReflection.text,
                    timestamp: queuedReflection.timestamp
                )
                successfullyReplayed.append(queuedReflection.id)
            } catch {}
        }

        let remainingQueue = queue.filter { !successfullyReplayed.contains($0.id) }
        self.saveQueueToStorage(remainingQueue)
        self.queuedCount = remainingQueue.count
        self.queueNearingCapacity = remainingQueue.count >= Self.queueWarningThreshold

        let replayedCount = successfullyReplayed.count
        if replayedCount > 0 {
            let message = replayedCount == 1
                ? "1 queued reflection saved"
                : "\(replayedCount) queued reflections saved"
            confirmationMessages.append(message)
        }

        for message in confirmationMessages {
            await self.addConfirmation(message)
        }
    }

    private func loadQueue() {
        let queue = self.loadQueueFromStorage()
        self.queuedCount = queue.count
        self.queueNearingCapacity = queue.count >= Self.queueWarningThreshold
    }

    private func loadQueueFromStorage() -> [QueuedReflection] {
        guard let data = UserDefaults.standard.data(forKey: Self.queueStorageKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([QueuedReflection].self, from: data)
        } catch {
            return []
        }
    }

    private func saveQueueToStorage(_ queue: [QueuedReflection]) {
        do {
            let data = try JSONEncoder().encode(queue)
            UserDefaults.standard.set(data, forKey: Self.queueStorageKey)
        } catch {}
    }

    private func addConfirmation(_ message: String) async {
        self.recentConfirmations.append(message)

        let task = Task {
            try? await Task.sleep(for: Self.confirmationDisplayDuration)
            if !Task.isCancelled, let index = self.recentConfirmations.firstIndex(of: message) {
                self.recentConfirmations.remove(at: index)
            }
        }
        self.confirmationTasks.append(task)

        await task.value

        
        self.confirmationTasks.removeAll { $0.isCancelled }
    }

    func clearQueue() {
        UserDefaults.standard.removeObject(forKey: Self.queueStorageKey)
        self.queuedCount = 0
        self.queueNearingCapacity = false
    }

    var currentQueueSize: Int {
        self.loadQueueFromStorage().count
    }
}
