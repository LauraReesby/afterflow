import SwiftUI

extension View {
    func applyNavigationAlerts(
        deepLinkAlert: Binding<(title: String, message: String)?>,
        showingDeleteConfirmation: Binding<Bool>,
        sessionPendingDeletion: Binding<(session: TherapeuticSession, index: Int)?>,
        confirmDelete: @escaping () -> Void
    ) -> some View {
        self
            .alert("Navigation Error", isPresented: Binding(
                get: { deepLinkAlert.wrappedValue != nil },
                set: { if !$0 { deepLinkAlert.wrappedValue = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deepLinkAlert.wrappedValue?.message ?? "")
            }
            .alert("Delete Session", isPresented: showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    confirmDelete()
                }
                .accessibilityIdentifier("confirmDeleteButton")
                Button("Cancel", role: .cancel) {
                    sessionPendingDeletion.wrappedValue = nil
                }
                .accessibilityIdentifier("cancelDeleteButton")
            } message: {
                if let pending = sessionPendingDeletion.wrappedValue {
                    let treatmentName = pending.session.treatmentType.displayName
                    let sessionDateFormatted = pending.session.sessionDate.formatted(date: .abbreviated, time: .omitted)
                    Text(
                        "Are you sure you want to delete this \(treatmentName) session from \(sessionDateFormatted)? " +
                            "This action cannot be undone."
                    )
                }
            }
    }
}
