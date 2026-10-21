import Foundation

/// Reading user-picked files: security-scoped access plus iCloud downloads.
enum ScopedFileAccess {
    static func readData(from url: URL) async throws -> Data {
        let didStart = url.startAccessingSecurityScopedResource()
        defer {
            if didStart {
                url.stopAccessingSecurityScopedResource()
            }
        }

        try await self.downloadIfNeeded(url: url)
        return try Data(contentsOf: url)
    }

    /// Callers must already hold security-scoped access to `url`.
    static func downloadIfNeeded(url: URL) async throws {
        let values = try url.resourceValues(forKeys: [.isUbiquitousItemKey])
        guard values.isUbiquitousItem == true else { return }

        try FileManager.default.startDownloadingUbiquitousItem(at: url)

        while true {
            let status = try url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
            if let downloadingStatus = status.ubiquitousItemDownloadingStatus,
               downloadingStatus == URLUbiquitousItemDownloadingStatus.current ||
               downloadingStatus == URLUbiquitousItemDownloadingStatus.downloaded {
                break
            }
            try await Task.sleep(nanoseconds: DesignConstants.Testing.downloadPollingInterval)
        }
    }
}
