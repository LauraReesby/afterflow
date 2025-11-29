import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SessionStore.self) private var sessionStore

    @State private var showingSessionForm = false
    @State private var listViewModel = SessionListViewModel()
    @State private var recentlyDeleted: (session: TherapeuticSession, index: Int)?
    @State private var showUndoBanner = false
    @State private var undoTask: Task<Void, Never>?

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(self.filteredSessions) { session in
                    NavigationLink {
                        SessionDetailView(session: session)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.displayTitle)
                                .font(.headline)
                            if session.status == .needsReflection {
                                Label("Needs Reflection", systemImage: "bell.badge")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else if session.status == .complete {
                                Label("Complete", systemImage: "checkmark.circle")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            if !session.intention.isEmpty {
                                Text(session.intention)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .accessibilityIdentifier("sessionRow-\(session.id.uuidString)")
                    }
                }
                .onDelete(perform: self.deleteSessions)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    self.filterMenu
                }
                ToolbarItem {
                    Button(action: { self.showingSessionForm = true }) {
                        Label("Add Session", systemImage: "plus")
                    }
                    .accessibilityIdentifier("addSessionButton")
                    .accessibilityLabel("Add Session")
                }
            }
            .navigationTitle("Sessions")
            .searchable(
                text: self.$listViewModel.searchText,
                placement: .toolbar,
                prompt: "Search sessions"
            )
            .listStyle(.insetGrouped)
            .toolbarBackground(.visible, for: .automatic)
            .scrollDismissesKeyboard(.immediately)
        } detail: {
            Text("Select a session")
        }
        .sheet(isPresented: self.$showingSessionForm) {
            SessionFormView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(16)
                .toolbarBackground(.visible, for: .automatic)
        }
        .overlay(alignment: .bottom) {
            if self.showUndoBanner, let deletedSession = recentlyDeleted?.session {
                UndoBannerView(
                    message: "Deleted \(deletedSession.displayTitle)",
                    actionTitle: "Undo",
                    action: self.undoDelete
                )
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var filteredSessions: [TherapeuticSession] {
        self.listViewModel.applyFilters(to: self.sessionStore.sessions)
    }

    private var filterMenu: some View {
        Menu {
            Picker("Sort", selection: self.$listViewModel.sortOption) {
                ForEach(SessionListViewModel.SortOption.allCases) { option in
                    Text(option.label).tag(option)
                }
            }

            Menu("Type") {
                Button("All Treatments") {
                    self.listViewModel.treatmentFilter = nil
                }
                ForEach(PsychedelicTreatmentType.allCases, id: \.self) { type in
                    Button(type.displayName) {
                        self.listViewModel.treatmentFilter = type
                    }
                }
            }
        } label: {
            Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Filter Sessions")
        .accessibilityHint("Change sort order or filter by treatment type")
    }

    private func deleteSessions(offsets: IndexSet) {
        withAnimation {
            guard let index = offsets.first else { return }
            let session = self.filteredSessions[index]
            try? self.sessionStore.delete(session)
            self.scheduleUndo(for: session, originalIndex: index)
        }
    }

    private func scheduleUndo(for session: TherapeuticSession, originalIndex: Int) {
        self.undoTask?.cancel()
        self.recentlyDeleted = (session, originalIndex)
        self.showUndoBanner = true

        self.undoTask = Task {
            try? await Task.sleep(for: .seconds(10))
            await MainActor.run {
                self.finalizeDeletion()
            }
        }
    }

    private func undoDelete() {
        guard let deleted = self.recentlyDeleted else { return }
        do {
            try self.sessionStore.create(deleted.session)
            self.recentlyDeleted = nil
            self.showUndoBanner = false
        } catch {
            // keep banner visible so user can try again
        }
        self.undoTask?.cancel()
        self.undoTask = nil
    }

    private func finalizeDeletion() {
        self.recentlyDeleted = nil
        self.showUndoBanner = false
        self.undoTask = nil
    }
}

#Preview {
    let container = try! ModelContainer(for: TherapeuticSession.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let store = SessionStore(modelContext: container.mainContext, owningContainer: container)
    return ContentView()
        .modelContainer(container)
        .environment(store)
}
