import SwiftUI

struct ExpandableSearchView: View {
    @Binding var searchText: String
    @Binding var treatmentFilter: PsychedelicTreatmentType?
    @Binding var sortOption: SessionListViewModel.SortOption
    let onCollapse: () -> Void

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: DesignConstants.Spacing.medium) {
            HStack(spacing: DesignConstants.Spacing.small) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                TextField("Search sessions", text: self.$searchText)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused(self.$isSearchFocused)
                    .accessibilityLabel("Search field")

                if !self.searchText.isEmpty {
                    Button {
                        self.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }

                Button {
                    self.onCollapse()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close search")
            }
            .padding(.horizontal, DesignConstants.Spacing.medium)
            .padding(.vertical, DesignConstants.Spacing.small)
            .background(
                RoundedRectangle(
                    cornerRadius: DesignConstants.CornerRadius.medium,
                    style: .continuous
                )
                .fill(Color(.systemGray6))
            )

            HStack(spacing: DesignConstants.Spacing.medium) {
                Menu {
                    Button("All Treatments") {
                        self.treatmentFilter = nil
                    }
                    ForEach(PsychedelicTreatmentType.allCases, id: \.self) { type in
                        Button(type.displayName) {
                            self.treatmentFilter = type
                        }
                    }
                } label: {
                    HStack {
                        Text(self.treatmentFilter?.displayName ?? "All Treatments")
                            .foregroundStyle(.primary)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityLabel("Filter by treatment type")
                .accessibilityValue(self.treatmentFilter?.displayName ?? "All treatments")

                Divider()
                    .frame(height: 20)

                Picker("Sort", selection: self.$sortOption) {
                    ForEach(SessionListViewModel.SortOption.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Sort order")
            }
            .padding(.horizontal, DesignConstants.Spacing.medium)
        }
        .padding(.vertical, DesignConstants.Spacing.medium)
        .padding(.horizontal, DesignConstants.Spacing.medium)
        .onAppear {
            self.isSearchFocused = true
        }
    }
}
