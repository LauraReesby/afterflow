import Foundation

enum MoodRatingScale {
    private static func clamped(_ value: Int) -> Int {
        max(1, min(value, 10))
    }

    static func descriptor(for value: Int) -> String {
        switch self.clamped(value) {
        case 1 ... 2:
            "Tender"
        case 3 ... 4:
            "Reflective"
        case 5 ... 6:
            "Centered"
        case 7 ... 8:
            "Uplifted"
        default:
            "Radiant"
        }
    }

    static func emoji(for value: Int) -> String {
        switch self.clamped(value) {
        case 1 ... 2:
            "☁️"
        case 3 ... 4:
            "🌦️"
        case 5 ... 6:
            "🌤️"
        case 7 ... 8:
            "☀️"
        default:
            "✨"
        }
    }
}
