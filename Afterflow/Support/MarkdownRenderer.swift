import Foundation
import SwiftUI

struct MarkdownRenderer {
    static func render(_ text: String) -> AttributedString {
        // Use SwiftUI's built-in markdown support (iOS 15+)
        do {
            return try AttributedString(markdown: text)
        } catch {
            // Fallback to plain text if markdown parsing fails
            return AttributedString(text)
        }
    }

    // Checks if text contains markdown formatting
    static func hasFormatting(_ text: String) -> Bool {
        let markdownPatterns = ["**", "*", "• ", "1. ", "2. ", "3. ", "#"]
        return markdownPatterns.contains { text.contains($0) }
    }
}
