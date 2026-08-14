import Charts
import SwiftUI

/// Mood-over-time trends, computed entirely on device from stored sessions.
struct TrendsView: View {
    let sessions: [TherapeuticSession]
    let onWordSelected: (String) -> Void

    @State private var viewModel = TrendsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignConstants.Spacing.lg) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mood over time")
                        .font(.afterflowDisplay(34))
                        .foregroundStyle(AF.text)
                    Text(self.subheadText)
                        .font(.afterflowBody(14))
                        .foregroundStyle(AF.neutral(600))
                }

                AFSegmentedControl(
                    selection: self.$viewModel.range,
                    options: TrendsViewModel.TrendsRange.allCases.map { ($0, $0.label) }
                )

                self.moodChartCard

                self.statTiles

                self.liftByTreatmentCard

                self.wordsCard
            }
            .padding(.horizontal, DesignConstants.Spacing.large)
            .padding(.top, DesignConstants.Spacing.md)
            .padding(.bottom, DesignConstants.Spacing.xl)
        }
        .background(AF.bg)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Trends")
                    .font(.afterflowBody(15, weight: .semibold))
                    .foregroundStyle(AF.text)
            }
        }
    }

    // MARK: - Header copy

    private var subheadText: String {
        let inRange = self.viewModel.filteredSessions(from: self.sessions)
        guard let earliest = inRange.first?.sessionDate else {
            return "Nothing logged in this range yet."
        }
        let startText = earliest.formatted(.dateTime.month(.abbreviated).year())
        let noun = inRange.count == 1 ? "session" : "sessions"
        return "\(inRange.count) \(noun), \(startText) to today."
    }

    // MARK: - Mood chart

    private var moodChartCard: some View {
        let before = self.viewModel.beforePoints(from: self.sessions)
        let after = self.viewModel.afterPoints(from: self.sessions)
        let lift = self.viewModel.averageLift(from: self.sessions)

        return VStack(alignment: .leading, spacing: DesignConstants.Spacing.medium) {
            HStack {
                KickerLabel("Mood, before and after")
                Spacer()
                if let lift {
                    Text(Self.signedText(lift) + " avg")
                        .font(.afterflowBody(13, weight: .semibold))
                        .foregroundStyle(AF.accent(700))
                }
            }

            if after.count >= 2 {
                Chart {
                    ForEach(Array(after.enumerated()), id: \.offset) { _, point in
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Mood", point.mood),
                            series: .value("Series", "after")
                        )
                        .foregroundStyle(AF.accent(200).opacity(0.55))
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Mood", point.mood),
                            series: .value("Series", "after")
                        )
                        .foregroundStyle(AF.accent(500))
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Mood", point.mood)
                        )
                        .foregroundStyle(AF.accent(500))
                        .symbolSize(38)
                    }

                    ForEach(Array(before.enumerated()), id: \.offset) { _, point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Mood", point.mood),
                            series: .value("Series", "before")
                        )
                        .foregroundStyle(AF.neutral(400))
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4]))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: 1 ... 10)
                .chartYAxis {
                    AxisMarks(values: [4, 8]) { _ in
                        AxisGridLine()
                            .foregroundStyle(AF.neutral(200))
                        AxisValueLabel()
                            .font(.system(size: 9))
                            .foregroundStyle(AF.neutral(500))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .font(.system(size: 9))
                            .foregroundStyle(AF.neutral(500))
                    }
                }
                .frame(height: 150)

                HStack(spacing: DesignConstants.Spacing.medium) {
                    HStack(spacing: 5) {
                        DashedSwatch()
                        Text("before")
                    }
                    HStack(spacing: 5) {
                        Capsule().fill(AF.accent(500)).frame(width: 14, height: 3)
                        Text("after")
                    }
                }
                .font(.afterflowBody(11))
                .foregroundStyle(AF.neutral(600))
            } else {
                Text("Reflect on two sessions to see your trends.")
                    .font(.afterflowBody(14))
                    .foregroundStyle(AF.neutral(600))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DesignConstants.Spacing.lg)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignConstants.CornerRadius.card, style: .continuous)
                .fill(AF.neutral(100))
        )
        .afShadow(.sm)
    }

    // MARK: - Stat tiles

    private var statTiles: some View {
        let reflected = self.viewModel.reflectedCount(from: self.sessions)
        let avgAfter = self.viewModel.averageMoodAfter(from: self.sessions)
        let daysBetween = self.viewModel.meanDaysBetween(from: self.sessions)

        return HStack(spacing: 10) {
            StatTile(
                value: "\(reflected)",
                caption: "sessions reflected",
                background: AF.accent2(200),
                foreground: AF.accent2(800)
            )
            StatTile(
                value: avgAfter.map { String(format: "%.1f", $0) } ?? "—",
                caption: "average mood after",
                background: AF.accent(200),
                foreground: AF.accent(800)
            )
            StatTile(
                value: daysBetween.map { "\(Int($0.rounded()))" } ?? "—",
                caption: "days between sessions",
                background: AF.neutral(200),
                foreground: AF.neutral(800)
            )
        }
    }

    // MARK: - Lift by treatment

    private var liftByTreatmentCard: some View {
        let rows = self.viewModel.liftByTreatment(from: self.sessions)
        let maxLift = rows.compactMap(\.lift).map(abs).max() ?? 1
        let footnote = self.viewModel.exclusionFootnote(from: self.sessions)

        return VStack(alignment: .leading, spacing: DesignConstants.Spacing.medium) {
            KickerLabel("Lift by treatment")

            VStack(spacing: 10) {
                ForEach(rows, id: \.treatment) { row in
                    HStack(spacing: 10) {
                        Text(row.treatment.displayName)
                            .font(.afterflowBody(13, weight: .semibold))
                            .foregroundStyle(AF.text)
                            .frame(width: 74, alignment: .leading)
                            .lineLimit(1)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule().fill(AF.neutral(200))
                                if let lift = row.lift, maxLift > 0 {
                                    Capsule()
                                        .fill(row.treatment.accentColor)
                                        .frame(
                                            width: max(
                                                10,
                                                geometry.size.width * abs(lift) / maxLift
                                            )
                                        )
                                }
                            }
                        }
                        .frame(height: 10)

                        Text(row.lift.map(Self.signedText) ?? "—")
                            .font(.afterflowBody(12))
                            .foregroundStyle(AF.neutral(700))
                            .frame(width: 38, alignment: .trailing)
                    }
                    .opacity(row.lift == nil ? 0.45 : 1)
                }
            }

            if let footnote {
                Text(footnote)
                    .font(.afterflowBody(11))
                    .foregroundStyle(AF.neutral(600))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignConstants.CornerRadius.card, style: .continuous)
                .fill(AF.neutral(100))
        )
        .afShadow(.sm)
    }

    // MARK: - Words

    private var wordsCard: some View {
        let words = self.viewModel.wordFrequencies(from: self.sessions)

        return VStack(alignment: .leading, spacing: DesignConstants.Spacing.medium) {
            KickerLabel("Words you return to")

            if words.isEmpty {
                Text("Your reflections will surface recurring words here.")
                    .font(.afterflowBody(13))
                    .foregroundStyle(AF.neutral(600))
            } else {
                FlowLayout(spacing: 7) {
                    ForEach(Array(words.enumerated()), id: \.element.word) { rank, entry in
                        Button {
                            self.onWordSelected(entry.word)
                        } label: {
                            Text(entry.word)
                                .font(.afterflowBody(self.wordFontSize(rank: rank), weight: .semibold))
                                .foregroundStyle(self.wordForeground(rank: rank))
                                .padding(.vertical, 6)
                                .padding(.horizontal, 13)
                        }
                        .buttonStyle(
                            AFCapsuleButtonStyle(
                                fill: self.wordBackground(rank: rank),
                                pressedFill: self.wordPressedBackground(rank: rank)
                            )
                        )
                        .accessibilityHint("Searches your sessions for this word")
                    }
                }

                Text("Counted from your own reflections on this device. Tap a word to see those sessions.")
                    .font(.afterflowBody(11))
                    .foregroundStyle(AF.neutral(600))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignConstants.CornerRadius.card, style: .continuous)
                .fill(AF.neutral(100))
        )
        .afShadow(.sm)
    }

    private func wordFontSize(rank: Int) -> CGFloat {
        switch rank {
        case 0: 16
        case 1: 15
        case 2, 3: 14
        case 4, 5: 13
        default: 12
        }
    }

    private func wordBackground(rank: Int) -> Color {
        switch rank {
        case 0: AF.accent(200)
        case 1: AF.accent2(200)
        default: AF.neutral(200)
        }
    }

    private func wordPressedBackground(rank: Int) -> Color {
        switch rank {
        case 0: AF.accent(300)
        case 1: AF.accent2(300)
        default: AF.neutral(300)
        }
    }

    private func wordForeground(rank: Int) -> Color {
        switch rank {
        case 0: AF.accent(800)
        case 1: AF.accent2(800)
        default: AF.neutral(700)
        }
    }

    private static func signedText(_ value: Double) -> String {
        let formatted = String(format: "%.1f", abs(value))
        if value > 0 { return "+\(formatted)" }
        if value < 0 { return "−\(formatted)" }
        return formatted
    }
}

private struct StatTile: View {
    let value: String
    let caption: String
    let background: Color
    let foreground: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(self.value)
                .font(.afterflowDisplay(26))
                .foregroundStyle(self.foreground)
            Text(self.caption)
                .font(.afterflowBody(11))
                .lineSpacing(11 * 0.3)
                .foregroundStyle(self.foreground.opacity(0.85))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignConstants.CornerRadius.card, style: .continuous)
                .fill(self.background)
        )
    }
}

private struct DashedSwatch: View {
    var body: some View {
        Line()
            .stroke(AF.neutral(400), style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
            .frame(width: 14, height: 2)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return path
        }
    }
}
