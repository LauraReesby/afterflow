import Foundation

protocol SpotifyAuthProviding {
    func refreshTokensIfNeeded() async throws -> SpotifyTokens
}

struct SpotifyPlaylist: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let imageURL: URL?
    let uri: String
    let trackCount: Int
}

protocol URLSessioning {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessioning {}

final class SpotifyService {
    enum SpotifyServiceError: Error {
        case unauthorized
        case invalidResponse
    }

    private let authProvider: SpotifyAuthProviding
    private let apiBase = URL(string: "https://api.spotify.com/v1")!
    private let urlSession: URLSessioning
    private var cachedPlaylists: [SpotifyPlaylist] = []

    init(authProvider: SpotifyAuthProviding, urlSession: URLSessioning = URLSession.shared) {
        self.authProvider = authProvider
        self.urlSession = urlSession
    }

    func fetchPlaylists() async throws -> [SpotifyPlaylist] {
        var request = URLRequest(url: apiBase.appendingPathComponent("me/playlists"))
        try await self.authorize(&request)
        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw SpotifyServiceError.invalidResponse }
            switch httpResponse.statusCode {
            case 200:
                let decoded = try JSONDecoder().decode(PlaylistListResponse.self, from: data)
                let playlists = decoded.items.map { item in
                    SpotifyPlaylist(
                        id: item.id,
                        name: item.name,
                        imageURL: item.images.first.flatMap { URL(string: $0.url) },
                        uri: item.uri,
                        trackCount: item.tracks.total
                    )
                }
                self.cachedPlaylists = playlists
                return playlists
            case 401:
                throw SpotifyServiceError.unauthorized
            default:
                throw SpotifyServiceError.invalidResponse
            }
        } catch {
            if let urlError = error as? URLError, urlError.code == .notConnectedToInternet, !cachedPlaylists.isEmpty {
                return self.cachedPlaylists
            }
            throw error
        }
    }

    func fetchPlaylistDetails(id: String) async throws -> SpotifyPlaylist {
        var request = URLRequest(url: apiBase.appendingPathComponent("playlists/\(id)"))
        try await self.authorize(&request)
        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw SpotifyServiceError.invalidResponse }
        switch httpResponse.statusCode {
        case 200:
            let item = try JSONDecoder().decode(PlaylistItem.self, from: data)
            return SpotifyPlaylist(
                id: item.id,
                name: item.name,
                imageURL: item.images.first.flatMap { URL(string: $0.url) },
                uri: item.uri,
                trackCount: item.tracks.total
            )
        case 401:
            throw SpotifyServiceError.unauthorized
        default:
            throw SpotifyServiceError.invalidResponse
        }
    }

    private func authorize(_ request: inout URLRequest) async throws {
        let tokens = try await authProvider.refreshTokensIfNeeded()
        request.httpMethod = "GET"
        request.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
    }
}

private struct PlaylistListResponse: Decodable {
    let items: [PlaylistItem]
}

private struct PlaylistItem: Decodable {
    struct Image: Decodable {
        let url: String
    }

    let id: String
    let name: String
    let images: [Image]
    let uri: String
    let tracks: Tracks

    struct Tracks: Decodable {
        let total: Int
    }
}
