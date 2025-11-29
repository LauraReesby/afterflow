import AuthenticationServices
import CryptoKit
import Foundation
import UIKit

struct SpotifyTokens: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let expirationDate: Date

    var isExpired: Bool {
        Date() >= self.expirationDate
    }
}

@MainActor
final class SpotifyAuthManager: NSObject {
    struct Configuration {
        let clientID: String
        let redirectURI: String
        let scopes: [String]
        let authorizeURL: URL
        let tokenURL: URL
    }

    private let configuration: Configuration
    private let secureStore: SecureStore
    private let tokenKey = "spotify_tokens"

    init(configuration: Configuration, secureStore: SecureStore? = nil) {
        self.configuration = configuration
        self.secureStore = secureStore ?? SecureStore()
    }

    // MARK: - PKCE

    struct PKCEPair {
        let verifier: String
        let challenge: String
    }

    func generatePKCEPair() -> PKCEPair {
        let verifier = Self.randomURLSafeString(length: 64)
        let challenge = Self.sha256Base64URL(verifier)
        return PKCEPair(verifier: verifier, challenge: challenge)
    }

    private static func randomURLSafeString(length: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func sha256Base64URL(_ string: String) -> String {
        let data = Data(string.utf8)
        let digest = SHA256.hash(data: data)
        return Data(digest).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    // MARK: - Authorization URL

    func makeAuthorizationURL(state: String = UUID().uuidString, pkce: PKCEPair) -> URL {
        var components = URLComponents(url: configuration.authorizeURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: self.configuration.clientID),
            URLQueryItem(name: "scope", value: self.configuration.scopes.joined(separator: " ")),
            URLQueryItem(name: "redirect_uri", value: self.configuration.redirectURI),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: pkce.challenge),
            URLQueryItem(name: "state", value: state)
        ]
        return components.url!
    }

    // MARK: - Token Handling

    func exchangeCodeForTokens(code: String, pkce: PKCEPair) async throws -> SpotifyTokens {
        var request = URLRequest(url: configuration.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type=authorization_code",
            "code=\(code)",
            "redirect_uri=\(configuration.redirectURI)",
            "client_id=\(self.configuration.clientID)",
            "code_verifier=\(pkce.verifier)"
        ].joined(separator: "&")
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SpotifyAuthError.tokenExchangeFailed
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        let tokens = SpotifyTokens(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            expirationDate: Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
        )
        try self.saveTokens(tokens)
        return tokens
    }

    func refreshTokensIfNeeded() async throws -> SpotifyTokens {
        if let tokens = try loadTokens(), !tokens.isExpired {
            return tokens
        }
        return try await self.refreshTokens()
    }

    private func refreshTokens() async throws -> SpotifyTokens {
        guard let stored = try loadTokens() else {
            throw SpotifyAuthError.notConnected
        }
        var request = URLRequest(url: configuration.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = [
            "grant_type=refresh_token",
            "refresh_token=\(stored.refreshToken)",
            "client_id=\(self.configuration.clientID)"
        ].joined(separator: "&")
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SpotifyAuthError.tokenRefreshFailed
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        let tokens = SpotifyTokens(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken.isEmpty ? stored.refreshToken : tokenResponse.refreshToken,
            expirationDate: Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
        )
        try self.saveTokens(tokens)
        return tokens
    }

    func disconnect() throws {
        try self.secureStore.remove(key: self.tokenKey)
    }

    func loadTokens() throws -> SpotifyTokens? {
        guard let data = try secureStore.data(for: tokenKey) else { return nil }
        return try JSONDecoder().decode(SpotifyTokens.self, from: data)
    }

    private func saveTokens(_ tokens: SpotifyTokens) throws {
        let data = try JSONEncoder().encode(tokens)
        try self.secureStore.set(data, for: self.tokenKey)
    }
}

extension SpotifyAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
            let window = scene.windows.first(where: { $0.isKeyWindow })
        else {
            return ASPresentationAnchor()
        }
        return window
    }
}

extension SpotifyAuthManager {
    enum SpotifyAuthError: Error {
        case tokenExchangeFailed
        case tokenRefreshFailed
        case notConnected
    }

    private struct TokenResponse: Decodable {
        let accessToken: String
        let tokenType: String
        let expiresIn: Int
        let refreshToken: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case tokenType = "token_type"
            case expiresIn = "expires_in"
            case refreshToken = "refresh_token"
        }
    }
}
