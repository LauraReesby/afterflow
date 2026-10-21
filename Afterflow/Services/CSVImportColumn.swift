import Foundation

/// The fields an imported spreadsheet row can supply, with the header names accepted for each.
enum CSVImportColumn: CaseIterable {
    case date
    case treatment
    case administration
    case intention
    case moodBefore
    case moodAfter
    case reflections
    case musicLink

    /// Header names that map to this column. Matching ignores case, surrounding whitespace, spaces,
    /// underscores and hyphens, so `Mood_Before`, `mood-before` and `mood before` are all equivalent.
    private var synonyms: [String] {
        switch self {
        case .date:
            ["date", "session date", "date time", "datetime", "when"]
        case .treatment:
            ["treatment type", "treatment", "substance", "medicine"]
        case .administration:
            ["administration", "route", "method"]
        case .intention:
            ["intention", "intent", "goal"]
        case .moodBefore:
            ["mood before", "before mood", "pre mood", "mood pre"]
        case .moodAfter:
            ["mood after", "after mood", "post mood", "mood post"]
        case .reflections:
            ["reflections", "reflection", "notes", "journal"]
        case .musicLink:
            ["music link url", "music link", "music", "playlist"]
        }
    }

    /// Lowercased header text with whitespace, underscores and hyphens removed.
    private static func compactKey(_ header: String) -> String {
        var key = ""
        for char in header.lowercased() where !char.isWhitespace && char != "_" && char != "-" {
            key.append(char)
        }
        return key
    }

    private static let columnsByKey: [String: CSVImportColumn] = {
        var table: [String: CSVImportColumn] = [:]
        for column in CSVImportColumn.allCases {
            for synonym in column.synonyms {
                table[CSVImportColumn.compactKey(synonym)] = column
            }
        }
        return table
    }()

    /// Maps each recognised column to its position in `header`. Unknown headers are ignored and,
    /// when two headers name the same column, the first one wins.
    static func indexes(in header: [String]) -> [CSVImportColumn: Int] {
        var result: [CSVImportColumn: Int] = [:]
        for (index, title) in header.enumerated() {
            guard let column = Self.columnsByKey[Self.compactKey(title)], result[column] == nil else { continue }
            result[column] = index
        }
        return result
    }
}

/// One data record plus the header mapping, so cells can be read by column regardless of order.
struct CSVImportRow {
    let fields: [String]
    let columns: [CSVImportColumn: Int]

    /// Raw cell text. Missing columns and rows shorter than the header read as blank.
    func text(_ column: CSVImportColumn) -> String {
        guard let index = self.columns[column], index < self.fields.count else { return "" }
        return self.fields[index]
    }

    func trimmedText(_ column: CSVImportColumn) -> String {
        self.text(column).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isBlank(_ fields: [String]) -> Bool {
        fields.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}
