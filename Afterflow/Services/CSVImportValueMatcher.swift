import Foundation

/// Turns free-form spreadsheet cell text into model values: treatment, administration and mood ratings.
enum CSVImportValueMatcher {
    enum MoodValue: Equatable {
        case blank
        case value(Int)
        case invalid
    }

    private static let moodRange: ClosedRange<Double> = 1 ... 10
    private static let moodScaleMaximum = 10.0

    static func treatment(for text: String) -> PsychedelicTreatmentType? {
        Self.treatmentsByKey[Self.key(text)]
    }

    static func administration(for text: String) -> AdministrationMethod? {
        Self.administrationsByKey[Self.key(text)]
    }

    /// Accepts `7`, ` 7 `, `7/10`, `7.0` and `6,5`; fractions round half up. Anything outside 1-10, or not a
    /// plain number, is `.invalid`; an empty cell is `.blank`.
    static func mood(from text: String) -> MoodValue {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .blank }

        let parts = trimmed.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
        if parts.count == 2, Self.decimalValue(String(parts[1])) != Self.moodScaleMaximum {
            return .invalid
        }
        guard let number = Self.decimalValue(String(parts[0])) else { return .invalid }

        let rounded = number.rounded(.toNearestOrAwayFromZero)
        guard Self.moodRange.contains(rounded) else { return .invalid }
        return .value(Int(rounded))
    }

    /// Strictly digits with at most one decimal separator; rejects signs, exponents, `inf` and `nan`.
    private static func decimalValue(_ text: String) -> Double? {
        let normalized = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        let separatorCount = normalized.filter { $0 == "." }.count
        guard !normalized.isEmpty, separatorCount <= 1,
              normalized.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == ".") })
        else { return nil }
        return Double(normalized)
    }

    private static func key(_ text: String) -> String {
        text.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    private static let treatmentsByKey: [String: PsychedelicTreatmentType] = {
        var table: [String: PsychedelicTreatmentType] = [
            "mushrooms": .psilocybin,
            "magic mushrooms": .psilocybin,
            "shrooms": .psilocybin,
            "acid": .lsd,
            "molly": .mdma,
            "ecstasy": .mdma,
            "esketamine": .ketamine,
            "spravato": .ketamine
        ]
        for type in PsychedelicTreatmentType.allCases {
            table[CSVImportValueMatcher.key(type.displayName)] = type
            table[CSVImportValueMatcher.key(type.rawValue)] = type
        }
        return table
    }()

    private static let administrationsByKey: [String: AdministrationMethod] = {
        var table: [String: AdministrationMethod] = [
            "iv": .intravenous,
            "intravenous": .intravenous,
            "im": .intramuscular,
            "intramuscular": .intramuscular,
            "intranasal": .nasal,
            "by mouth": .oral
        ]
        for method in AdministrationMethod.allCases {
            table[CSVImportValueMatcher.key(method.displayName)] = method
            table[CSVImportValueMatcher.key(method.rawValue)] = method
        }
        return table
    }()
}
