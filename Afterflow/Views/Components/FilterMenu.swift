import SwiftUI

struct FilterMenu: View {
    @Binding var listViewModel: SessionListViewModel

    var body: some View {
        Menu {
            Picker("Sort", selection: self.$listViewModel.sortOption) {
                ForEach(SessionListViewModel.SortOption.allCases) { option in
                    Text(option.label).tag(option)
                }
            }

            Menu("Type") {
                Button("All Treatments") { self.listViewModel.treatmentFilter = nil }
                ForEach(PsychedelicTreatmentType.allCases, id: \.self) { type in
                    Button(type.displayName) { self.listViewModel.treatmentFilter = type }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
                .font(.title3)
        }
        .accessibilityLabel("Filter Sessions")
        .accessibilityHint("Change sort order or filter by treatment type")
    }
}
