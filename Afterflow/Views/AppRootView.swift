import SwiftData
import SwiftUI

/// Shows the app once the store is open, otherwise the recovery screen.
struct AppRootView: View {
    let startup: AppStartup

    var body: some View {
        switch self.startup.state {
        case let .ready(services):
            ContentView()
                .modelContainer(services.container)
                .environment(services.sessionStore)
                .environmentObject(services.notificationHandler)
        case let .needsRecovery(error):
            StoreRecoveryView(
                error: error,
                persistence: self.startup.persistence,
                onRetry: self.startup.retry,
                onStartFresh: self.startup.startFresh
            )
        }
    }
}
