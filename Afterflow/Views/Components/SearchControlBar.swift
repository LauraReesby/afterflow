import SwiftUI

struct SearchControlBar: View {
    @Binding var listViewModel: SessionListViewModel
    @Binding var showCalendarView: Bool
    @Binding var isSearchExpanded: Bool
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if self.isSearchExpanded {
                ExpandableSearchView(
                    searchText: self.$listViewModel.searchText,
                    treatmentFilter: self.$listViewModel.treatmentFilter,
                    sortOption: self.$listViewModel.sortOption,
                    onCollapse: {
                        withAnimation(
                            .easeInOut(duration: DesignConstants.Animation.standardDuration)
                        ) {
                            self.isSearchExpanded = false
                        }
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))

                Divider()
                    .opacity(DesignConstants.Opacity.light)
                    .padding(.horizontal, DesignConstants.Spacing.medium)
            }

            HStack(spacing: 24) {
                self.searchButton
                self.calendarButton
                self.addButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .glassPillBackground(cornerRadius: 22)
        .shadow(
            color: .black.opacity(DesignConstants.Shadow.standardOpacity),
            radius: DesignConstants.Shadow.standardRadius,
            x: DesignConstants.Shadow.standardX,
            y: DesignConstants.Shadow.standardY
        )
        .padding(.horizontal, DesignConstants.Spacing.small)
        .padding(.bottom, DesignConstants.Spacing.small)
        .animation(
            .easeInOut(duration: DesignConstants.Animation.standardDuration),
            value: self.isSearchExpanded
        )
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    private var searchButton: some View {
        Button {
            withAnimation(
                .easeInOut(duration: DesignConstants.Animation.standardDuration)
            ) {
                self.isSearchExpanded.toggle()
            }
        } label: {
            Image(
                systemName: "magnifyingglass"
            )
            .font(.title2)
            .foregroundStyle(.secondary)
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(self.isSearchExpanded ? "Hide search" : "Search sessions")
        .accessibilityHint("Tap to expand search and filter controls")
    }

    private var calendarButton: some View {
        Button {
            if self.isSearchExpanded {
                self.isSearchExpanded = false
            }
            withAnimation(
                .spring(
                    response: DesignConstants.Animation.springResponse,
                    dampingFraction: DesignConstants.Animation.springDampingFraction
                )
            ) {
                self.showCalendarView.toggle()
            }
        } label: {
            Image(
                systemName: self.showCalendarView ? "list.bullet" : "calendar"
            )
            .font(.title2)
            .foregroundStyle(.secondary)
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(self.showCalendarView ? "Show List" : "Show Calendar")
        .accessibilityHint("Toggles between calendar and list view")
    }

    private var addButton: some View {
        Button(action: self.onAdd) {
            Image(systemName: "plus")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("addSessionButton")
        .accessibilityLabel("Add Session")
        .accessibilityHint("Creates a new therapy session")
    }
}
