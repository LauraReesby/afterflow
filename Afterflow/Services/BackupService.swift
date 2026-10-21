import Foundation

struct BackupService {
    func makeBackup(
        sessions: [TherapeuticSession],
        exportedAt: Date = Date(),
        appVersion: String? = BackupService.currentAppVersion
    ) -> AfterflowBackup {
        AfterflowBackup(
            formatVersion: AfterflowBackup.currentFormatVersion,
            exportedAt: exportedAt,
            appVersion: appVersion,
            sessions: sessions.map { SessionBackupRecord(session: $0) }
        )
    }

    func encode(_ backup: AfterflowBackup) throws -> Data {
        do {
            return try Self.makeEncoder().encode(backup)
        } catch {
            throw BackupError.encodingFailed
        }
    }

    /// Backs up every session passed in; callers must not pre-filter.
    func encode(sessions: [TherapeuticSession], exportedAt: Date = Date()) throws -> Data {
        try self.encode(self.makeBackup(sessions: sessions, exportedAt: exportedAt))
    }

    /// The version is read on its own first so a file from a newer app is reported
    /// as such even if its session layout no longer matches this version's.
    func decode(_ data: Data) throws -> AfterflowBackup {
        let decoder = Self.makeDecoder()

        let header: BackupHeader
        do {
            header = try decoder.decode(BackupHeader.self, from: data)
        } catch {
            throw BackupError.invalidFile
        }
        guard header.formatVersion >= 1 else { throw BackupError.invalidFile }
        guard header.formatVersion <= AfterflowBackup.currentFormatVersion else {
            throw BackupError.unsupportedVersion(header.formatVersion)
        }

        do {
            return try decoder.decode(AfterflowBackup.self, from: data)
        } catch {
            throw BackupError.invalidFile
        }
    }

    /// Default filename without extension; the file exporter appends `.json`.
    static func filename(for date: Date) -> String {
        "Afterflow-Backup-\(self.filenameFormatter.string(from: date))"
    }

    static func lastBackupText(for date: Date?, now: Date = Date()) -> String {
        guard let date else { return "Not backed up yet" }
        guard now.timeIntervalSince(date) >= 60 else { return "Last backup: just now" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Last backup: \(formatter.localizedString(for: date, relativeTo: now))"
    }

    static var currentAppVersion: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    // Dates are written as raw `Double`s (seconds since the reference date), not
    // ISO 8601, which would drop fractional seconds and break exact round-trips.
    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .deferredToDate
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .deferredToDate
        return decoder
    }

    private static let filenameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

private nonisolated struct BackupHeader: Decodable {
    let formatVersion: Int
}
