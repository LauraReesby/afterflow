@testable import Afterflow
import Foundation
import Testing

@MainActor
struct SecureStoreTests {
    private let store = SecureStore(service: "test.afterflow.securestore")

    @Test("SecureStore set/get/remove roundtrip") func roundTrip() async throws {
        let key = "token"
        let payload = Data("hello".utf8)
        try self.store.set(payload, for: key)
        let stored = try #require(try self.store.data(for: key))
        #expect(stored == payload)
        try self.store.remove(key: key)
        let missing = try store.data(for: key)
        #expect(missing == nil)
    }
}
