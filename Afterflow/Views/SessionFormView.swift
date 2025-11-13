//  Constitutional Compliance: Privacy-First, SwiftUI Native, Therapeutic Value-First

import SwiftUI
import SwiftData

struct SessionFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Form State
    @State private var sessionDate = Date()
    @State private var selectedTreatmentType = PsychedelicTreatmentType.psilocybin
    @State private var dosage = ""
    @State private var selectedAdministration = AdministrationMethod.oral
    @State private var intention = ""
    
    // MARK: - UI State
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker(
                        "Session Date",
                        selection: $sessionDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                } header: {
                    Text("When")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Section {
                    Picker("Treatment Type", selection: $selectedTreatmentType) {
                        ForEach(PsychedelicTreatmentType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    TextField("Dosage (e.g., 3.5g, 100μg)", text: $dosage)
                        .textContentType(.none)
                        .autocorrectionDisabled()
                    
                    Picker("Administration", selection: $selectedAdministration) {
                        ForEach(AdministrationMethod.allCases, id: \.self) { method in
                            Text(method.displayName).tag(method)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Treatment")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Section {
                    TextField(
                        "What do you hope to explore or heal?",
                        text: $intention,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                    .textContentType(.none)
                } header: {
                    Text("Intention")
                        .font(.headline)
                        .foregroundColor(.primary)
                } footer: {
                    Text("Take a moment to reflect on your hopes for this session")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSession()
                    }
                    .disabled(isLoading || intention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .disabled(isLoading)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Actions
    
    private func saveSession() {
        guard !intention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError(message: "Please add an intention for your session")
            return
        }
        
        isLoading = true
        
        let newSession = TherapeuticSession(
            sessionDate: sessionDate,
            treatmentType: selectedTreatmentType,
            dosage: dosage.trimmingCharacters(in: .whitespacesAndNewlines),
            administration: selectedAdministration,
            intention: intention.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        do {
            modelContext.insert(newSession)
            try modelContext.save()
            
            // Success - dismiss the form
            dismiss()
        } catch {
            isLoading = false
            showError(message: "Unable to save session: \(error.localizedDescription)")
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

#Preview {
    SessionFormView()
        .modelContainer(for: TherapeuticSession.self, inMemory: true)
}