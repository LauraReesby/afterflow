import Foundation
import SwiftUI

struct FullWidthSearchBar: View {
    @Binding var searchText: String
    @Binding var isExpanded: Bool
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        HStack(spacing: DesignConstants.Spacing.medium) {
            HStack(spacing: DesignConstants.Spacing.small) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.body)

                TextField("Search sessions", text: self.$searchText)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused(self.$isSearchFieldFocused)

                if !self.searchText.isEmpty {
                    Button {
                        self.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                    .accessibilityHint("Clears the search text")
                }
            }
            .padding(.horizontal, DesignConstants.Spacing.medium)
            .padding(.vertical, DesignConstants.Spacing.small)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignConstants.CornerRadius.medium, style: .continuous)
                    .fill(Color(.systemGray6))
            )

            Button {
                self.searchText = ""
                self.isExpanded = false
            } label: {
                Image(systemName: "xmark")
                    .font(.title3)
            }
            .tint(.primary)
            .accessibilityLabel("Cancel search")
            .accessibilityHint("Closes the search and returns to the session list")
        }
        .padding(.horizontal, DesignConstants.Spacing.large)
        .padding(.vertical, DesignConstants.Spacing.small)
        .onAppear {
            self.isSearchFieldFocused = true
        }
    }
}
