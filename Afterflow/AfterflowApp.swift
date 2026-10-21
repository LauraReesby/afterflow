import SwiftUI
import UIKit

@MainActor
class AppDelegate: NSObject, UIApplicationDelegate {
    lazy var startup: AppStartup = .init()

    override init() {
        super.init()
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Opening the store also wires the notification delegate, so touch it before launch completes.
        _ = self.startup
        return true
    }
}

@main
struct AfterflowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let isUITesting: Bool = ProcessInfo.processInfo.arguments.contains("-ui-testing")

    init() {
        FontRegistrar.registerBundledFonts()
        if ProcessInfo.processInfo.arguments.contains("-ui-musiclink-fixtures") {
            let delegate = self.appDelegate
            DispatchQueue.main.async {
                delegate.startup.seedMusicLinkFixturesIfNeeded()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(startup: self.appDelegate.startup)
        }
    }
}
