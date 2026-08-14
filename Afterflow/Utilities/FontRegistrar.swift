import CoreText
import Foundation

/// Registers the bundled Caprasimo and Figtree fonts at launch.
/// The project uses a generated Info.plist (no `UIAppFonts` array), so fonts are
/// registered through CoreText instead of plist-based loading. Offline-first:
/// the TTFs ship in the bundle and nothing is fetched at runtime.
enum FontRegistrar {
    private static var didRegister = false

    static func registerBundledFonts() {
        guard !didRegister else { return }
        didRegister = true

        let fontNames = [
            "Caprasimo-Regular",
            "Figtree-Regular",
            "Figtree-SemiBold",
            "Figtree-Bold"
        ]

        for name in fontNames {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                assertionFailure("Bundled font missing: \(name).ttf")
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                // Already-registered errors are benign (e.g. repeated launches in tests).
                let code = (error?.takeRetainedValue() as Error?).map { ($0 as NSError).code }
                if code != CTFontManagerError.alreadyRegistered.rawValue,
                   code != CTFontManagerError.duplicatedName.rawValue {
                    assertionFailure("Failed to register font \(name): \(String(describing: code))")
                }
            }
        }
    }
}
