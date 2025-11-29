@testable import Afterflow
import Foundation
import Testing

private final class MockAuthProvider: SpotifyAuthProviding {
    var tokens = SpotifyTokens(
        accessToken: "token",
        refreshToken: "refresh",
        expirationDate: Date().addingTimeInterval(3600)
    )

    func refreshTokensIfNeeded() async throws -> SpotifyTokens { self.tokens }
}

private final class MockSession: URLSessioning {
    enum Step {
        case response(Data, statusCode: Int)
        case error(Error)
    }

    private var steps: [Step]

    init(steps: [Step]) {
        self.steps = steps
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard !steps.isEmpty else { throw URLError(.badServerResponse) }
        let step = steps.removeFirst()
        switch step {
        case let .response(data, statusCode):
            let response = HTTPURLResponse(
                url: request.url ?? URL(string: "https://example.com")!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (data, response)
        case let .error(error):
            throw error
        }
    }
}

@MainActor
struct SpotifyServiceTests {
    private let authProvider = MockAuthProvider()

    @Test("fetchPlaylists converts response to SpotifyPlaylist") func fetchPlaylists() async throws {
        let json = Data("""
        {"items": [{"id": "abc", "name": "My Playlist", "images": [{"url": "https://example.com/art"}], "uri": "spotify:playlist:abc", "tracks": {"total": 10}}]}
        """.utf8)
        let service = SpotifyService(
            authProvider: authProvider,
            urlSession: MockSession(steps: [.response(json, statusCode: 200)])
        )
        let playlists = try await service.fetchPlaylists()
        #expect(playlists.count == 1)
        #expect(playlists.first?.name == "My Playlist")
        #expect(playlists.first?.trackCount == 10)
    }

    @Test("fetchPlaylistDetails parses trackCount") func fetchDetails() async throws {
        let json = Data("""
        {"id": "abc", "name": "Detail", "images": [], "uri": "spotify:playlist:abc", "tracks": {"total": 5}}
        """.utf8)
        let service = SpotifyService(
            authProvider: authProvider,
            urlSession: MockSession(steps: [.response(json, statusCode: 200)])
        )
        let playlist = try await service.fetchPlaylistDetails(id: "abc")
        #expect(playlist.trackCount == 5)
    }

    @Test("offline fallback returns cached playlists") func offlineFallback() async throws {
        let json = Data("""
        {"items": [{"id": "abc", "name": "Cached", "images": [], "uri": "spotify:playlist:abc", "tracks": {"total": 3}}]}
        """.utf8)
        let service = SpotifyService(
            authProvider: authProvider,
            urlSession: MockSession(steps: [
                .response(json, statusCode: 200),
                .error(URLError(.notConnectedToInternet))
            ])
        )
        _ = try await service.fetchPlaylists()
        let playlists = try await service.fetchPlaylists()
        #expect(playlists.first?.name == "Cached")
    }

    @Test("unauthorized response throws error") func unauthorized() async throws {
        let json = Data("""
        {"items": []}
        """.utf8)
        let service = SpotifyService(
            authProvider: authProvider,
            urlSession: MockSession(steps: [.response(json, statusCode: 401)])
        )
        await #expect(throws: SpotifyService.SpotifyServiceError.unauthorized) {
            _ = try await service.fetchPlaylists()
        }
    }
}
