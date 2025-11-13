import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var sessions: [TherapeuticSession]
    @State private var showingSessionForm = false

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(sessions) { session in
                    NavigationLink {
                        Text("Session: \(session.displayTitle)")
                    } label: {
                        VStack(alignment: .leading) {
                            Text(session.displayTitle)
                                .font(.headline)
                            if !session.intention.isEmpty {
                                Text(session.intention)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteSessions)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: { showingSessionForm = true }) {
                        Label("Add Session", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Afterflow Sessions")
        } detail: {
            Text("Select a session")
        }
        .sheet(isPresented: $showingSessionForm) {
            SessionFormView()
        }
    }

    private func deleteSessions(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(sessions[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TherapeuticSession.self, inMemory: true)
}
