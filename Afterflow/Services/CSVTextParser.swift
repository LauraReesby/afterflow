import Foundation

/// Text-level CSV handling: decoding, line endings, delimiter detection and record splitting.
enum CSVTextParser {
    private static let utf8ByteOrderMark = Data([0xEF, 0xBB, 0xBF])
    private static let byteOrderMarkScalar: Unicode.Scalar = "\u{FEFF}"

    /// Supported delimiters in tie-break order: comma wins over semicolon, which wins over tab.
    private static let supportedDelimiters: [Character] = [",", ";", "\t"]

    /// Decodes spreadsheet exports: UTF-8 first, then the legacy Windows-1252 and Mac Roman code pages that older
    /// Excel versions write. Text containing NUL characters (UTF-16 or binary files) is rejected.
    static func decode(_ data: Data) -> String? {
        var payload = data
        if payload.starts(with: Self.utf8ByteOrderMark) {
            payload = payload.dropFirst(Self.utf8ByteOrderMark.count)
        }

        for encoding in [String.Encoding.utf8, .windowsCP1252, .macOSRoman] {
            if let text = String(data: payload, encoding: encoding), !text.contains("\u{0}") {
                return text
            }
        }
        return nil
    }

    static func stripByteOrderMark(from text: String) -> String {
        guard text.unicodeScalars.first == Self.byteOrderMarkScalar else { return text }
        var scalars = text.unicodeScalars
        scalars.removeFirst()
        return String(scalars)
    }

    static func normalizeLineEndings(_ text: String) -> String {
        text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
    }

    /// Picks the delimiter that occurs most often outside quotes on the first non-empty line.
    /// Expects line endings to be normalised already.
    static func detectDelimiter(in text: String) -> Character {
        var counts: [Character: Int] = [:]
        var insideQuotes = false
        var sawContent = false

        for char in text {
            if char == "\n", !insideQuotes {
                if sawContent { break }
                continue
            }
            sawContent = true
            if char == "\"" {
                insideQuotes.toggle()
            } else if !insideQuotes, Self.supportedDelimiters.contains(char) {
                counts[char, default: 0] += 1
            }
        }

        var best: Character = ","
        var bestCount = 0
        for candidate in Self.supportedDelimiters {
            let count = counts[candidate] ?? 0
            if count > bestCount {
                best = candidate
                bestCount = count
            }
        }
        return best
    }

    /// Splits normalised text into records of fields, honouring quoted fields and doubled quotes.
    static func parse(_ text: String, delimiter: Character) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var insideQuotes = false

        let characters = Array(text)
        var index = 0
        while index < characters.count {
            let char = characters[index]
            if char == "\"" {
                if insideQuotes, index + 1 < characters.count, characters[index + 1] == "\"" {
                    field.append("\"")
                    index += 2
                    continue
                }
                insideQuotes.toggle()
                index += 1
                continue
            }

            if char == delimiter, !insideQuotes {
                row.append(field)
                field = ""
                index += 1
                continue
            }

            if char == "\n", !insideQuotes {
                row.append(field)
                rows.append(row)
                row = []
                field = ""
                index += 1
                continue
            }

            field.append(char)
            index += 1
        }

        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }

        return rows
    }
}
