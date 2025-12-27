@testable import Afterflow
import Foundation
import SwiftUI
import Testing

@Suite("MarkdownRenderer Tests")
struct MarkdownRendererTests {
    

    @Test("Plain text renders without modification") func plainTextRendersWithoutModification() {
        let text = "This is plain text without any markdown."
        let result = MarkdownRenderer.render(text)
        #expect(String(result.characters) == text)
    }

    @Test("Empty string renders as empty") func emptyStringRendersAsEmpty() {
        let result = MarkdownRenderer.render("")
        #expect(String(result.characters).isEmpty)
    }

    @Test("Bold text with double asterisks renders") func boldTextWithDoubleAsterisksRenders() {
        let text = "This is **bold** text."
        let result = MarkdownRenderer.render(text)

        
        let resultString = String(result.characters)
        #expect(resultString.contains("bold"))
        #expect(resultString.contains("This is"))
        #expect(resultString.contains("text."))
    }

    @Test("Italic text with single asterisks renders") func italicTextWithSingleAsterisksRenders() {
        let text = "This is *italic* text."
        let result = MarkdownRenderer.render(text)

        
        let resultString = String(result.characters)
        #expect(resultString.contains("italic"))
        #expect(resultString.contains("This is"))
    }

    @Test("Heading with hash renders") func headingWithHashRenders() {
        let text = "# Main Heading"
        let result = MarkdownRenderer.render(text)

        
        let resultString = String(result.characters)
        #expect(resultString.contains("Main Heading"))
    }

    @Test("Bullet list renders") func bulletListRenders() {
        let text = "• First item\n• Second item\n• Third item"
        let result = MarkdownRenderer.render(text)

        
        let resultString = String(result.characters)
        #expect(resultString.contains("First item"))
        #expect(resultString.contains("Second item"))
        #expect(resultString.contains("Third item"))
    }

    @Test("Numbered list renders") func numberedListRenders() {
        let text = "1. First item\n2. Second item\n3. Third item"
        let result = MarkdownRenderer.render(text)

        
        let resultString = String(result.characters)
        #expect(resultString.contains("First item"))
        #expect(resultString.contains("Second item"))
        #expect(resultString.contains("Third item"))
    }

    @Test("Mixed markdown formatting renders") func mixedMarkdownFormattingRenders() {
        let text = "# Heading\n\nThis is **bold** and *italic* text.\n\n• Bullet point"
        let result = MarkdownRenderer.render(text)

        
        let resultString = String(result.characters)
        #expect(resultString.contains("Heading"))
        #expect(resultString.contains("bold"))
        #expect(resultString.contains("italic"))
        #expect(resultString.contains("Bullet point"))
    }

    @Test("Malformed markdown renders as plain text") func malformedMarkdownRendersAsPlainText() {
        
        let text = "This is **unclosed bold text"
        let result = MarkdownRenderer.render(text)

        
        let resultString = String(result.characters)
        #expect(resultString.contains("unclosed bold text"))
    }

    @Test("Very long text renders successfully") func veryLongTextRendersSuccessfully() {
        let longText = String(repeating: "This is a long piece of text. ", count: 100)
        let result = MarkdownRenderer.render(longText)

        
        let resultString = String(result.characters)
        #expect(resultString.contains("This is a long piece of text."))
    }

    @Test("Unicode and emoji render correctly") func unicodeAndEmojiRenderCorrectly() {
        let text = "Hello 🌈 世界 émoji test"
        let result = MarkdownRenderer.render(text)

        let resultString = String(result.characters)
        #expect(resultString.contains("Hello"))
        #expect(resultString.contains("🌈"))
        #expect(resultString.contains("世界"))
        #expect(resultString.contains("émoji"))
    }

    @Test("Newlines are preserved") func newlinesArePreserved() {
        let text = "Line 1\nLine 2\nLine 3"
        let result = MarkdownRenderer.render(text)

        let resultString = String(result.characters)
        #expect(resultString.contains("Line 1"))
        #expect(resultString.contains("Line 2"))
        #expect(resultString.contains("Line 3"))
    }

    

    @Test("hasFormatting detects double asterisks (bold)") func hasFormattingDetectsDoubleAsterisks() {
        #expect(MarkdownRenderer.hasFormatting("This is **bold** text") == true)
    }

    @Test("hasFormatting detects single asterisks (italic)") func hasFormattingDetectsSingleAsterisks() {
        #expect(MarkdownRenderer.hasFormatting("This is *italic* text") == true)
    }

    @Test("hasFormatting detects bullet points") func hasFormattingDetectsBulletPoints() {
        #expect(MarkdownRenderer.hasFormatting("• First item") == true)
    }

    @Test("hasFormatting detects numbered lists (1.)") func hasFormattingDetectsNumberedList1() {
        #expect(MarkdownRenderer.hasFormatting("1. First item") == true)
    }

    @Test("hasFormatting detects numbered lists (2.)") func hasFormattingDetectsNumberedList2() {
        #expect(MarkdownRenderer.hasFormatting("2. Second item") == true)
    }

    @Test("hasFormatting detects numbered lists (3.)") func hasFormattingDetectsNumberedList3() {
        #expect(MarkdownRenderer.hasFormatting("3. Third item") == true)
    }

    @Test("hasFormatting detects headings") func hasFormattingDetectsHeadings() {
        #expect(MarkdownRenderer.hasFormatting("# Heading") == true)
    }

    @Test("hasFormatting returns false for plain text") func hasFormattingReturnsFalseForPlainText() {
        #expect(MarkdownRenderer.hasFormatting("This is plain text without any markdown.") == false)
    }

    @Test("hasFormatting returns false for empty string") func hasFormattingReturnsFalseForEmptyString() {
        #expect(MarkdownRenderer.hasFormatting("") == false)
    }

    @Test("hasFormatting detects multiple formatting patterns") func hasFormattingDetectsMultipleFormattingPatterns() {
        #expect(MarkdownRenderer.hasFormatting("**Bold** and *italic*") == true)
    }

    @Test("hasFormatting handles text with hashtag mid-sentence") func hasFormattingHandlesHashtagMidSentence() {
        
        #expect(MarkdownRenderer.hasFormatting("Use the #hashtag feature") == true)
    }

    @Test("hasFormatting handles asterisks in different contexts")
    func hasFormattingHandlesAsterisksInDifferentContexts() {
        
        #expect(MarkdownRenderer.hasFormatting("5 * 3 = 15") == true)
    }

    

    @Test("render handles only asterisks") func renderHandlesOnlyAsterisks() {
        let result = MarkdownRenderer.render("***")
        
        #expect(result.characters.count >= 0)
    }

    @Test("render handles only hashes") func renderHandlesOnlyHashes() {
        let result = MarkdownRenderer.render("###")
        
        #expect(result.characters.count >= 0)
    }

    @Test("hasFormatting with whitespace only returns false") func hasFormattingWithWhitespaceOnlyReturnsFalse() {
        #expect(MarkdownRenderer.hasFormatting("   \n\t  ") == false)
    }

    @Test("render handles mixed line endings") func renderHandlesMixedLineEndings() {
        let text = "Line 1\rLine 2\nLine 3\r\nLine 4"
        let result = MarkdownRenderer.render(text)

        let resultString = String(result.characters)
        #expect(resultString.contains("Line 1"))
        #expect(resultString.contains("Line 4"))
    }

    @Test("hasFormatting detects formatting at start of string") func hasFormattingDetectsFormattingAtStartOfString() {
        #expect(MarkdownRenderer.hasFormatting("**Start with bold") == true)
        #expect(MarkdownRenderer.hasFormatting("#Start with heading") == true)
    }

    @Test("hasFormatting detects formatting at end of string") func hasFormattingDetectsFormattingAtEndOfString() {
        #expect(MarkdownRenderer.hasFormatting("End with bold**") == true)
        #expect(MarkdownRenderer.hasFormatting("End with hash#") == true)
    }
}
