import Foundation
import SwiftUI

struct ValidationErrorView: View {
    let message: String?

    var body: some View {
        if let message {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.orange)
                    .font(.caption)
                    .accessibilityHidden(true)

                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("validation_suggestion_text")
                    .accessibilityLabel("Validation suggestion: \(message)")

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.orange.opacity(0.1))
                    .stroke(.orange.opacity(0.3), lineWidth: 1)
            )
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .animation(.easeInOut(duration: 0.2), value: message)
        }
    }
}

struct InlineValidationModifier: ViewModifier {
    let isValid: Bool?

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        self.isValid == false ? .orange.opacity(0.5) : .clear,
                        lineWidth: 1
                    )
                    .allowsHitTesting(false)
            )
    }
}

extension View {
    func inlineValidation(_ validationResult: FieldValidationState?) -> some View {
        self.modifier(InlineValidationModifier(isValid: validationResult?.isValid))
    }
}

#if DEBUG
    struct ValidationErrorView_Previews: PreviewProvider {
        static var previews: some View {
            VStack(spacing: 20) {
                // Example with error message
                TextField("Intention", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
                    .inlineValidation(.invalid)

                // Example with no error
                TextField("Dosage", text: .constant("3.5g"))
                    .textFieldStyle(.roundedBorder)
                    .inlineValidation(.valid)

                // Direct error view
                ValidationErrorView(message: "Please provide more context before saving")
            }
            .padding()
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")

            VStack(spacing: 20) {
                TextField("Intention", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
                    .inlineValidation(.invalid)
            }
            .padding()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
#endif
