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
                if self.showFormatting {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FormatButton(symbol: "bold", action: { self.applyFormatting("**", "**") })
                            FormatButton(symbol: "italic", action: { self.applyFormatting("*", "*") })
                            FormatButton(symbol: "list.bullet", action: { self.applyFormatting("• ", "") })
                            FormatButton(symbol: "number", action: { self.applyFormatting("1. ", "") })
                        }
                        .padding(.horizontal, 4)
                    }
                    .frame(height: 36)
                }

                ZStack(alignment: .topLeading) {
                    TextEditor(text: self.$text)
                        .frame(minHeight: 140)
                        .focused(self.$isFieldFocused)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(self.isFieldFocused ? Color.accentColor : Color.clear, lineWidth: 1)
                        )
                        .onChange(of: self.isFieldFocused) { _, newValue in
                            self.isFocused.wrappedValue = newValue
                        }
                        .accessibilityIdentifier(self.accessibilityIdentifier ?? "")

                    if self.text.isEmpty, !self.isFieldFocused {
                        Text("Capture integration notes, insights, or any memories...")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }

                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.showFormatting.toggle()
                        }
                    } label: {
                        Label(
                            self.showFormatting ? "Hide Formatting" : "Show Formatting",
                            systemImage: "textformat"
                        )
                        .labelStyle(.titleOnly)
                        .font(.caption)
                    }
                    .buttonStyle(.borderless)

                    Spacer()

                    Text("\(self.text.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier(self.accessibilityIdentifier ?? "")
        }

        private func applyFormatting(_ prefix: String, _ suffix: String) {
            self.text += prefix + suffix
        }
    }

    private struct FormatButton: View {
        let symbol: String
        let action: () -> Void

        var body: some View {
            Button(action: self.action) {
                Image(systemName: self.symbol)
                    .font(.body)
                    .frame(width: 32, height: 32)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(6)
            }
        }
    }

#else
    
    struct RichTextEditor: View {
        @Binding var text: String
        @FocusState.Binding var isFocused: Bool

        var body: some View {
            TextEditor(text: self.$text)
                .frame(minHeight: 140)
                .focused(self.$isFocused)
        }
    }
#endif

#Preview {
    @Previewable @State var text = ""
    @Previewable @State var isFocused = false

    return RichTextEditor(text: $text, isFocused: $isFocused)
        .padding()
}
