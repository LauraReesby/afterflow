import SwiftUI

extension View {
    func applySettingsAlert(settingsError: Binding<String?>) -> some View {
        self.alert("Settings", isPresented: Binding(
            get: { settingsError.wrappedValue != nil },
            set: { if !$0 { settingsError.wrappedValue = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(settingsError.wrappedValue ?? "")
        }
    }
}
