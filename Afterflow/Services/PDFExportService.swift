import Foundation
#if canImport(UIKit)
    import UIKit
#endif

struct PDFExportService: Sendable {
    struct Options: Sendable {
        var includeCoverPage: Bool = true
        var showPrivacyNote: Bool = true
    }

    func export(
        sessions: [TherapeuticSession],
        dateRange: ClosedRange<Date>? = nil,
        treatmentType: PsychedelicTreatmentType? = nil,
        options: Options = Options()
    ) throws -> URL {
        #if canImport(UIKit)
            let filtered = sessions.filter { session in
                if let range = dateRange, !range.contains(session.sessionDate) { return false }
                if let type = treatmentType, session.treatmentType != type { return false }
                return true
            }

            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("Afterflow-Export-\(UUID().uuidString).pdf")

            let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter @72dpi
            let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

            let data = renderer.pdfData { context in
                var cursor = PDFCursor(pageRect: pageRect)

                if options.includeCoverPage {
                    context.beginPage()
                    cursor.reset()
                    self.drawCoverPage(cursor: &cursor, options: options)
                }

                if filtered.isEmpty {
                    context.beginPage()
                    cursor.reset()
                    self.drawEmptyState(cursor: &cursor)
                } else {
                    for session in filtered {
                        self.ensurePageSpace(context: context, cursor: &cursor, minimumRemaining: 140)
                        self.drawSession(session, cursor: &cursor)
                    }
                }
            }

            try data.write(to: fileURL, options: .atomic)
            return fileURL
        #else
            throw PDFExportError.platformUnavailable
        #endif
    }

    enum PDFExportError: Error {
        case platformUnavailable
    }

    #if canImport(UIKit)
        private func drawCoverPage(cursor: inout PDFCursor, options: Options) {
            self.drawTitle("Session Export", cursor: &cursor, size: 28, weight: .bold)
            cursor.advance(by: 12)
            self.drawBody(
                "Generated on \(Self.dateTimeFormatter.string(from: Date()))",
                cursor: &cursor,
                color: .secondaryLabel
            )
            cursor.advance(by: 24)
        }

        private func drawEmptyState(cursor: inout PDFCursor) {
            self.drawTitle("No sessions found", cursor: &cursor, size: 18, weight: .semibold)
            cursor.advance(by: 8)
            self.drawBody("Adjust filters or add sessions to export.", cursor: &cursor, color: .secondaryLabel)
        }

        private func drawSession(_ session: TherapeuticSession, cursor: inout PDFCursor) {
            self.drawTitle(session.displayTitle, cursor: &cursor, size: 18, weight: .semibold)
            cursor.advance(by: 6)
            self.drawBody("Date/Time: \(Self.dateTimeFormatter.string(from: session.sessionDate))", cursor: &cursor)
            self.drawBody("Treatment: \(session.treatmentType.displayName)", cursor: &cursor)
            self.drawBody("Administration: \(session.administration.displayName)", cursor: &cursor)
            self.drawBody("Mood: \(session.moodBefore) → \(session.moodAfter)", cursor: &cursor)
            if !session.intention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.drawBody("Intention: \(session.intention)", cursor: &cursor)
            }
            if !session.reflections.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.drawBody("Reflections: \(session.reflections)", cursor: &cursor)
            }
            if let link = session.musicLinkURL ?? session.musicLinkWebURL, !link.isEmpty {
                self.drawBody("Music Link: \(link)", cursor: &cursor, color: .systemBlue)
            }
            cursor.advance(by: 12)
        }

        private func ensurePageSpace(
            context: UIGraphicsPDFRendererContext,
            cursor: inout PDFCursor,
            minimumRemaining: CGFloat
        ) {
            let remaining = cursor.pageRect.height - cursor.y - cursor.margin
            if remaining < minimumRemaining {
                context.beginPage()
                cursor.reset()
            }
        }

        private func drawTitle(_ text: String, cursor: inout PDFCursor, size: CGFloat, weight: UIFont.Weight) {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size, weight: weight),
                .foregroundColor: UIColor.label
            ]
            let bounding = text.boundingRect(
                with: CGSize(width: cursor.contentWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin],
                attributes: attrs,
                context: nil
            )
            text.draw(
                in: CGRect(x: cursor.x, y: cursor.y, width: cursor.contentWidth, height: ceil(bounding.height)),
                withAttributes: attrs
            )
            cursor.advance(by: ceil(bounding.height))
        }

        private func drawBody(_ text: String, cursor: inout PDFCursor, color: UIColor = .label) {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: color
            ]
            let bounding = text.boundingRect(
                with: CGSize(width: cursor.contentWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin],
                attributes: attrs,
                context: nil
            )
            text.draw(
                in: CGRect(x: cursor.x, y: cursor.y, width: cursor.contentWidth, height: ceil(bounding.height)),
                withAttributes: attrs
            )
            cursor.advance(by: ceil(bounding.height))
        }
    #endif

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

#if canImport(UIKit)
    private struct PDFCursor {
        let pageRect: CGRect
        let margin: CGFloat = 40
        var x: CGFloat
        var y: CGFloat
        var contentWidth: CGFloat { self.pageRect.width - (self.margin * 2) }

        init(pageRect: CGRect) {
            self.pageRect = pageRect
            self.x = self.margin
            self.y = self.margin
        }

        mutating func advance(by amount: CGFloat) {
            self.y += amount
        }

        mutating func reset() {
            self.x = self.margin
            self.y = self.margin
        }
    }
#endif
