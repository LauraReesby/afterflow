@testable import Afterflow
import Foundation
import Testing

@MainActor
struct MusicLinkMetadataServiceTests {
    private final class MockSession: URLSessioning {
        enum Step {
            case response(Data, Int)
            case error(Error)
        }

        private var steps: [Step]
        init(steps: [Step]) { self.steps = steps }

        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
            guard !self.steps.isEmpty else { throw URLError(.badServerResponse) }
            let step = self.steps.removeFirst()
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

    @Test("Classifies Spotify deep link into canonical URL") func classifyDeepLink() async throws {
        let service = MusicLinkMetadataService()
        let result = service.classify(urlString: "spotify:playlist:37i9dQZF1DXcBWIGoYBM5M")
        #expect(result?.provider == .spotify)
        #expect(result?.canonicalURL.absoluteString == "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M")
    }

    @Test("Fetches Spotify oEmbed metadata") func fetchSpotifyMetadata() async throws {
        let payload = Data("""
        {
          "title": "Deep Focus",
          "author_name": "Spotify",
          "thumbnail_url": "https://i.scdn.co/image/test",
          "duration": 4980
        }
        """.utf8)
        let service = MusicLinkMetadataService(
            urlSession: MockSession(steps: [.response(payload, 200)])
        )
        let metadata = try await service.fetchMetadata(for: "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M")
        #expect(metadata.provider == .spotify)
        #expect(metadata.title == "Deep Focus")
        #expect(metadata.authorName == "Spotify")
        #expect(metadata.thumbnailURL?.absoluteString == "https://i.scdn.co/image/test")
        #expect(metadata.durationSeconds == 4980)
    }

    @Test("Unsupported provider falls back to link-only metadata") func fallbackForUnsupportedProvider() async throws {
        let service = MusicLinkMetadataService()
        let metadata = try await service.fetchMetadata(for: "https://music.apple.com/us/playlist/calm/pl.u-123")
        #expect(metadata.provider == .appleMusic)
        #expect(metadata.title == "Calm")
        #expect(metadata.thumbnailURL == nil)
    }

    @Test("Classifies Apple Podcasts link and falls back to minimal metadata") func classifyApplePodcastsLink(
    ) async throws {
        let service = MusicLinkMetadataService()
        let url = "https://podcasts.apple.com/us/podcast/example-show/id1234567890"
        let classification = service.classify(urlString: url)
        #expect(classification?.provider == .applePodcasts)
        #expect(classification?.canonicalURL.absoluteString == url)

        let metadata = try await service.fetchMetadata(for: url)
        #expect(metadata.provider == .applePodcasts)
        #expect(metadata.title == "Example Show")
        #expect(metadata.thumbnailURL == nil)
    }

    @Test("Classifies YouTube short link into canonical URL") func classifyYouTubeShortLink() async throws {
        let service = MusicLinkMetadataService()
        let result = service.classify(urlString: "https://youtu.be/abcd1234")
        #expect(result?.provider == .youtube)
        #expect(result?.canonicalURL.absoluteString == "https://www.youtube.com/watch?v=abcd1234")
    }

    @Test("Fetches YouTube oEmbed metadata") func fetchYouTubeMetadata() async throws {
        let payload = Data("""
        {
          "title": "Morning Energy",
          "author_name": "Slow Vibes",
          "thumbnail_url": "https://img.youtube.com/vi/track/default.jpg"
        }
        """.utf8)
        let service = MusicLinkMetadataService(
            urlSession: MockSession(steps: [.response(payload, 200)])
        )
        let metadata = try await service.fetchMetadata(for: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        #expect(metadata.provider == .youtube)
        #expect(metadata.title == "Morning Energy")
        #expect(metadata.authorName == "Slow Vibes")
        #expect(metadata.thumbnailURL?.absoluteString == "https://img.youtube.com/vi/track/default.jpg")
    }

    @Test("Network failures fall back to minimal metadata instead of throwing") func requestFailureFallsBack(
    ) async throws {
        let service = MusicLinkMetadataService(
            urlSession: MockSession(steps: [.error(URLError(.timedOut))])
        )
        let metadata = try await service.fetchMetadata(for: "https://open.spotify.com/playlist/123")
        #expect(metadata.provider == .spotify)
        #expect(metadata.title == nil)
        #expect(metadata.thumbnailURL == nil)
    }

    @Test("SoundCloud oEmbed fetches metadata") func soundCloudOEmbed() async throws {
        let payload = Data("""
        {
          "title": "Gentle Waves",
          "author_name": "Calm Artist",
          "thumbnail_url": "https://soundcloud.com/thumb.png"
        }
        """.utf8)
        let service = MusicLinkMetadataService(
            urlSession: MockSession(steps: [.response(payload, 200)])
        )
        let metadata = try await service.fetchMetadata(for: "https://soundcloud.com/artist/track")
        #expect(metadata.provider == .soundcloud)
        #expect(metadata.title == "Gentle Waves")
        #expect(metadata.authorName == "Calm Artist")
        #expect(metadata.thumbnailURL?.absoluteString == "https://soundcloud.com/thumb.png")
    }

    @Test("Bandcamp fallback infers title from path") func bandcampTitleInference() async throws {
        let service = MusicLinkMetadataService()
        let metadata = try await service.fetchMetadata(for: "https://artist.bandcamp.com/album/blue-waves")
        #expect(metadata.provider == .bandcamp)
        #expect(metadata.title == "Blue Waves")
    }

    @Test("Tidal fallback infers title from path") func tidalTitleInference() async throws {
        let service = MusicLinkMetadataService()
        let metadata = try await service.fetchMetadata(for: "https://tidal.com/album/deep-focus")
        #expect(metadata.provider == .tidal)
        #expect(metadata.title == "Deep Focus")
    }

    @Test("Tidal classification and oEmbed metadata") func tidalOEmbed() async throws {
        let payload = Data("""
        {
          "title": "Chill Sessions",
          "author_name": "Tidal Artist",
          "thumbnail_url": "https://tidal.com/thumb.png"
        }
        """.utf8)
        let service = MusicLinkMetadataService(
            urlSession: MockSession(steps: [.response(payload, 200)])
        )
        let metadata = try await service.fetchMetadata(for: "https://tidal.com/browse/playlist/abc123")
        #expect(metadata.provider == .tidal)
        #expect(metadata.title == "Chill Sessions")
        #expect(metadata.authorName == "Tidal Artist")
        #expect(metadata.thumbnailURL?.absoluteString == "https://tidal.com/thumb.png")
    }

    @Test("Successful fetches cache results to avoid duplicate requests") func cachingPreventsDuplicateRequests(
    ) async throws {
        let payload = Data("""
        {
          "title": "Deep Focus",
          "author_name": "Spotify",
          "thumbnail_url": "https://i.scdn.co/image/test"
        }
        """.utf8)
        let service = MusicLinkMetadataService(
            urlSession: MockSession(steps: [.response(payload, 200)])
        )

        let first = try await service.fetchMetadata(for: "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M")
        #expect(first.title == "Deep Focus")

        // second fetch should hit cache even though the mock has no steps left
        let second = try await service.fetchMetadata(for: "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M")
        #expect(second.title == "Deep Focus")
    }
}
