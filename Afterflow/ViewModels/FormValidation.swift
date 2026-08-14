import Foundation

struct FieldValidationState {
    let isValid: Bool

    static let valid = FieldValidationState(isValid: true)
    static let invalid = FieldValidationState(isValid: false)
}

struct SessionFormData {
    let sessionDate: Date
    let treatmentType: PsychedelicTreatmentType
    let administration: AdministrationMethod
    let intention: String
}

struct FormValidation {
    private static let earliestValidSessionDate: TimeInterval = -10 * 365 * 24 * 60 * 60

    private static let futureToleranceInterval: TimeInterval = 60 * 60 * 8

    func validateIntention(_ intention: String) -> FieldValidationState {
        let trimmed = intention.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return .invalid
        }

        return .valid
    }

    func validateSessionDate(_ date: Date) -> FieldValidationState {
        let now = Date()
        let normalizedDate = self.normalizeSessionDate(date)

        let maxFutureDate = now.addingTimeInterval(Self.futureToleranceInterval)
        if normalizedDate > maxFutureDate {
            return .invalid
        }

        let earliestDate = now.addingTimeInterval(Self.earliestValidSessionDate)
        if normalizedDate < earliestDate {
            return .invalid
        }

        return .valid
    }

    func normalizeSessionDate(_ date: Date) -> Date {
        let calendar = Calendar.current

        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)

        if let minute = components.minute {
            let roundedMinute = ((minute + 7) / 15) * 15
            if roundedMinute >= 60 {
                // Rounding up past the hour: roll the whole date forward so day,
                // month, and year boundaries carry correctly (23:53+ used to wrap
                // the hour to 0 without advancing the day).
                components.minute = 0
                if let base = calendar.date(from: components) {
                    return calendar.date(byAdding: .hour, value: 1, to: base) ?? date
                }
            } else {
                components.minute = roundedMinute
            }
        }

        return calendar.date(from: components) ?? date
    }

    func getDateNormalizationMessage(originalDate: Date, normalizedDate: Date) -> String? {
        let timeDifference = abs(normalizedDate.timeIntervalSince(originalDate))

        guard timeDifference > 60 else { return nil }

        let formatter = DateFormatter()
        formatter.timeStyle = .short

        let normalizedTimeString = formatter.string(from: normalizedDate)
        return "Time adjusted to \(normalizedTimeString) for easier session tracking"
    }

    func validateForm(_ formData: SessionFormData) -> Bool {
        self.validateIntention(formData.intention).isValid &&
            self.validateSessionDate(formData.sessionDate).isValid
    }
}
