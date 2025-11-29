//  Constitutional Compliance: Privacy-First, SwiftUI Native, Therapeutic Value-First

import Foundation

/// Represents whether a particular form field passes validation.
struct FieldValidationState {
    let isValid: Bool

    static let valid = FieldValidationState(isValid: true)
    static let invalid = FieldValidationState(isValid: false)
}

/// Form data structure for session creation
struct SessionFormData {
    let sessionDate: Date
    let treatmentType: PsychedelicTreatmentType
    let administration: AdministrationMethod
    let intention: String
}

/// Form validation service with therapeutic tone messaging
struct FormValidation {
    // MARK: - Date Validation Constants

    /// Reasonable range for therapeutic sessions (10 years ago to today)
    private static let earliestValidSessionDate: TimeInterval = -10 * 365 * 24 * 60 * 60 // 10 years ago

    /// Latest valid time for "today" sessions (allow up to 1 hour in future for scheduling)
    private static let futureToleranceInterval: TimeInterval = 60 * 60 // 1 hour

    // MARK: - Validation Methods

    /// Validate intention field
    func validateIntention(_ intention: String) -> FieldValidationState {
        let trimmed = intention.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return .invalid
        }

        return .valid
    }

    /// Validate session date with enhanced normalization and therapeutic messaging
    func validateSessionDate(_ date: Date) -> FieldValidationState {
        let now = Date()
        let normalizedDate = self.normalizeSessionDate(date)

        // Check if date is too far in the future
        let maxFutureDate = now.addingTimeInterval(Self.futureToleranceInterval)
        if normalizedDate > maxFutureDate {
            return .invalid
        }

        // Check if date is unreasonably old for therapeutic sessions
        let earliestDate = now.addingTimeInterval(Self.earliestValidSessionDate)
        if normalizedDate < earliestDate {
            return .invalid
        }

        return .valid
    }

    /// Normalize session date for therapeutic context
    /// - Rounds minutes to nearest 15-minute interval
    /// - Ensures timezone consistency
    /// - Returns standardized date for storage
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

    /// Get user-friendly description of date normalization changes
    func getDateNormalizationMessage(originalDate: Date, normalizedDate: Date) -> String? {
        let timeDifference = abs(normalizedDate.timeIntervalSince(originalDate))

        // Only show message if there was a significant change (more than 1 minute)
        guard timeDifference > 60 else { return nil }

        let formatter = DateFormatter()
        formatter.timeStyle = .short

        let normalizedTimeString = formatter.string(from: normalizedDate)
        return "Time adjusted to \(normalizedTimeString) for easier session tracking"
    }

    /// Validate complete form data
    func validateForm(_ formData: SessionFormData) -> Bool {
        self.validateIntention(formData.intention).isValid &&
            self.validateSessionDate(formData.sessionDate).isValid
    }
}
