@testable import Afterflow
import Testing
import UIKit

struct FontRegistrarTests {
    @Test("Bundled fonts register and resolve by PostScript name")
    func bundledFontsResolve() async throws {
        FontRegistrar.registerBundledFonts()

        #expect(UIFont(name: "Caprasimo-Regular", size: 12) != nil)
        #expect(UIFont(name: "Figtree-Regular", size: 12) != nil)
        #expect(UIFont(name: "Figtree-SemiBold", size: 12) != nil)
        #expect(UIFont(name: "Figtree-Bold", size: 12) != nil)
    }
}
