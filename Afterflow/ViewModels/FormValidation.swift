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
    private static let earliestValidSessionDate: TimeInterval = -10 * 365 * 24 * 60 * 60 // 10 years ago

    private static let futureToleranceInterval: TimeInterval = 60 * 60 * 8 // 8 hour

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

        // Get date components in current timezone
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)

        // Round minutes to nearest 15-minute interval (therapeutic sessions typically align to quarters)
        if let minute = components.minute {
            let roundedMinute = ((minute + 7) / 15) * 15 // Round to nearest 15
            components.minute = roundedMinute >= 60 ? 0 : roundedMinute

            // Handle hour overflow if minute was rounded to 60
            if roundedMinute >= 60, let hour = components.hour {
                components.hour = (hour + 1) % 24
            }
        }

        // Create normalized date
        let normalizedDate = calendar.date(from: components) ?? date

        return normalizedDate
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
