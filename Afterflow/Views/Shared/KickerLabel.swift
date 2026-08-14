import SwiftUI

/// Section label in the Organic kicker style ("WHEN", "MOOD", "INTENTION").
struct KickerLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(self.text)
            .kicker()
    }
}
