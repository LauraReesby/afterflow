import Foundation

protocol URLSessioning {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessioning {}

struct MusicLinkMetadata: Equatable {
    let provider: MusicLinkProvider
    let originalURL: URL
    let canonicalURL: URL
    let title: String?
    let authorName: String?
    let thumbnailURL: URL?
}

final class MusicLinkMetadataService {
    enum ServiceError: Error {
        case invalidURL
        case requestFailed
        case decodingFailed
    }

    struct ClassificationResult {
        let provider: MusicLinkProvider
        let originalURL: URL
        let canonicalURL: URL
    }

    private let urlSession: URLSessioning
    private let timeout: TimeInterval
    private var cache: [String: MusicLinkMetadata] = [:]

    init(urlSession: URLSessioning = URLSession.shared, timeout: TimeInterval = 3.0) {
        self.urlSession = urlSession
        self.timeout = timeout
    }

    func classify(urlString: String) -> ClassificationResult? {
        guard let originalURL = Self.normalize(urlString: urlString) else { return nil }
        let provider = Self.provider(for: originalURL)
        let canonical = provider.fallbackWebURL(for: originalURL) ?? originalURL
        return ClassificationResult(provider: provider, originalURL: originalURL, canonicalURL: canonical)
    }

    func fetchMetadata(for urlString: String) async throws -> MusicLinkMetadata {
        guard let classification = self.classify(urlString: urlString) else {
            throw ServiceError.invalidURL
        }

        let cacheKey = classification.canonicalURL.absoluteString.lowercased()
        if let cached = self.cache[cacheKey] {
            return cached
        }

        let metadata: MusicLinkMetadata

        if classification.provider.supportsOEmbed,
           let endpoint = classification.provider.oEmbedURL(for: classification.canonicalURL) {
            do {
                let payload = try await self.fetchOEmbedPayload(endpoint: endpoint)
                metadata = MusicLinkMetadata(
                    provider: classification.provider,
                    originalURL: classification.originalURL,
                    canonicalURL: classification.canonicalURL,
                    title: payload.title,
                    authorName: payload.authorName,
                    thumbnailURL: payload.thumbnailURL
                )
            } catch {
                metadata = self.fallbackMetadata(for: classification)
            }
        } else {
            metadata = self.fallbackMetadata(for: classification)
        }

        self.cache[cacheKey] = metadata
        return metadata
    }

    private func fetchOEmbedPayload(endpoint: URL) async throws -> OEmbedResponse {
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = self.timeout

        let (data, response) = try await self.urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ServiceError.requestFailed
        }

        let decoder = JSONDecoder()
        guard let payload = try? decoder.decode(OEmbedResponse.self, from: data) else {
            throw ServiceError.decodingFailed
        }
        return payload
    }

    private func fallbackMetadata(for classification: ClassificationResult) -> MusicLinkMetadata {
        MusicLinkMetadata(
            provider: classification.provider,
            originalURL: classification.originalURL,
            canonicalURL: classification.canonicalURL,
            title: nil,
            authorName: nil,
            thumbnailURL: nil
        )
    }

    // MARK: - Helpers

    private static func normalize(urlString: String) -> URL? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.lowercased().hasPrefix("spotify:") {
            return URL(string: trimmed)
        }

        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return URL(string: trimmed)
        }

        if trimmed.hasPrefix("//") {
            return URL(string: "https:\(trimmed)")
        }

        return URL(string: "https://\(trimmed)")
    }

    private static func provider(for url: URL) -> MusicLinkProvider {
        if let scheme = url.scheme?.lowercased(), scheme == "spotify" {
            return .spotify
        }

        guard var host = url.host?.lowercased() else { return .linkOnly }
        if host.hasPrefix("www.") { host.removeFirst(4) }

        if host.contains("spotify.com") { return .spotify }
        if host.contains("youtube.com") || host == "youtu.be" || host
            .contains("youtube-nocookie.com") { return .youtube }
        if host.contains("soundcloud.com") { return .soundcloud }
        if host.contains("music.apple.com") || host.contains("itunes.apple.com") { return .appleMusic }
        if host.contains("bandcamp.com") { return .bandcamp }
        return .linkOnly
    }
}

private struct OEmbedResponse: Decodable {
    let title: String?
    let authorName: String?
    let thumbnailURL: URL?

    enum CodingKeys: String, CodingKey {
        case title
        case authorName = "author_name"
        case thumbnailURL = "thumbnail_url"
    }
}
