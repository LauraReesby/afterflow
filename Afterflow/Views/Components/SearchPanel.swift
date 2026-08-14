import SwiftUI

/// The expanded search state of the sessions list: active field, treatment
/// filter chips, and sort control, in one bordered card.
struct SearchPanel: View {
    @Binding var searchText: String
    @Binding var treatmentFilter: PsychedelicTreatmentType?
    @Binding var sortOption: SessionListViewModel.SortOption
    let onCollapse: () -> Void

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DesignConstants.Spacing.medium) {
            HStack(spacing: DesignConstants.Spacing.small) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AF.neutral(600))
                    .accessibilityHidden(true)

                TextField("Search intentions and reflections", text: self.$searchText)
                    .font(.afterflowBody(15))
                    .foregroundStyle(AF.text)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused(self.$isSearchFocused)
                    .accessibilityLabel("Search field")

                Button {
                    self.onCollapse()
                } label: {
                    Text("Done")
                        .font(.afterflowBody(13, weight: .semibold))
                        .foregroundStyle(AF.accent(700))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Done")
                .accessibilityHint("Closes the search panel and keeps the current query")
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(Capsule().fill(AF.neutral(200)))

            FlowLayout(spacing: 7) {
                AFChip(
                    label: "All",
                    isSelected: self.treatmentFilter == nil
                ) {
                    self.treatmentFilter = nil
                }
                ForEach(PsychedelicTreatmentType.allCases, id: \.self) { type in
                    AFChip(
                        label: type.displayName,
                        isSelected: self.treatmentFilter == type
                    ) {
                        self.treatmentFilter = self.treatmentFilter == type ? nil : type
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Filter by treatment type")

            VStack(alignment: .leading, spacing: 6) {
                KickerLabel("Sort")
                AFSegmentedControl(
                    selection: self.$sortOption,
                    options: [
                        (.newestFirst, "Newest"),
                        (.oldestFirst, "Oldest"),
                        (.moodChange, "Mood lift")
                    ]
                )
                .accessibilityLabel("Sort order")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: DesignConstants.CornerRadius.card, style: .continuous)
                .fill(AF.neutral(100))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignConstants.CornerRadius.card, style: .continuous)
                .strokeBorder(AF.neutral(200), lineWidth: 1)
        )
        .onAppear {
            self.isSearchFocused = true
        }
    }
}
