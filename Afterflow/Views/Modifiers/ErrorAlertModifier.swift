import SwiftUI

extension View {
    /// Displays an error alert with a customizable title and error message binding.
    /// The alert automatically dismisses when the binding is set to nil.
    ///
    /// - Parameters:
    ///   - title: The title of the alert. Defaults to "Error".
    ///   - error: A binding to an optional error message string.
    /// - Returns: A view with the error alert modifier applied.
    func errorAlert(
        title: String = "Error",
        error: Binding<String?>
    ) -> some View {
        alert(title, isPresented: Binding(
            get: { error.wrappedValue != nil },
            set: { if !$0 { error.wrappedValue = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(error.wrappedValue ?? "")
        }
    }
}
