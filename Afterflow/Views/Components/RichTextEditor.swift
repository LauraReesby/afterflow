import SwiftUI

#if canImport(UIKit)
import UIKit

struct RichTextEditor: View {
    @Binding var text: String
    var isFocused: Binding<Bool>
    var accessibilityIdentifier: String?

    @State private var showFormatting = false
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Formatting toolbar
            if showFormatting {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FormatButton(symbol: "bold", action: { applyFormatting("**", "**") })
                        FormatButton(symbol: "italic", action: { applyFormatting("*", "*") })
                        FormatButton(symbol: "list.bullet", action: { applyFormatting("• ", "") })
                        FormatButton(symbol: "number", action: { applyFormatting("1. ", "") })
                    }
                    .padding(.horizontal, 4)
                }
                .frame(height: 36)
            }

            // Text editor
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .frame(minHeight: 140)
                    .focused($isFieldFocused)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isFieldFocused ? Color.accentColor : Color.clear, lineWidth: 1)
                    )
                    .onChange(of: isFieldFocused) { _, newValue in
                        isFocused.wrappedValue = newValue
                    }
                    .accessibilityIdentifier(accessibilityIdentifier ?? "")

                if text.isEmpty && !isFieldFocused {
                    Text("Capture integration notes, insights, or any memories...")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }

            // Toggle formatting button
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showFormatting.toggle()
                    }
                } label: {
                    Label(
                        showFormatting ? "Hide Formatting" : "Show Formatting",
                        systemImage: "textformat"
                    )
                    .labelStyle(.titleOnly)
                    .font(.caption)
                }
                .buttonStyle(.borderless)

                Spacer()

                Text("\(text.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityIdentifier(accessibilityIdentifier ?? "")
    }

    private func applyFormatting(_ prefix: String, _ suffix: String) {
        text += prefix + suffix
    }
}

private struct FormatButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.body)
                .frame(width: 32, height: 32)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(6)
        }
    }
}

#else
// Fallback for non-UIKit platforms
struct RichTextEditor: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        TextEditor(text: $text)
            .frame(minHeight: 140)
            .focused($isFocused)
    }
}
#endif

#Preview {
    @Previewable @State var text = ""
    @Previewable @State var isFocused = false

    return RichTextEditor(text: $text, isFocused: $isFocused)
        .padding()
}
