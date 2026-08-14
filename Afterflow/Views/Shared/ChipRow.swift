import SwiftUI

/// A wrapping flow layout for chip rows.
struct FlowLayout: Layout {
    var spacing: CGFloat = 7

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = self.computeRows(proposal: proposal, subviews: subviews)
        let width = proposal.width ?? rows.map(\.width).max() ?? 0
        let height = rows.reduce(0) { $0 + $1.height } + CGFloat(max(0, rows.count - 1)) * self.spacing
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = self.computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + self.spacing
            }
            y += row.height + self.spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [Row] = []
        var current = Row()

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let widthIfAdded = current.width + (current.indices.isEmpty ? 0 : self.spacing) + size.width
            if !current.indices.isEmpty, widthIfAdded > maxWidth {
                rows.append(current)
                current = Row()
            }
            current.width += (current.indices.isEmpty ? 0 : self.spacing) + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty {
            rows.append(current)
        }
        return rows
    }
}

/// Single-tap toggle chip in the Organic style.
struct AFChip: View {
    enum Style {
        /// Selected: terracotta fill, cream label. Unselected: outline.
        case accent
        /// Selected: sage tint. Used for prompt chips.
        case sage
    }

    enum Size {
        /// 13/600, padding 6x13 — filter chips.
        case small
        /// 14/600, padding 9x14 — form chips.
        case medium
    }

    let label: String
    let isSelected: Bool
    var style: Style = .accent
    var size: Size = .small
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            Text(self.label)
                .font(.afterflowBody(self.fontSize, weight: .semibold))
                .foregroundStyle(self.foreground)
                .padding(.vertical, self.verticalPadding)
                .padding(.horizontal, self.horizontalPadding)
        }
        .buttonStyle(
            AFChipButtonStyle(
                fill: self.background,
                pressedFill: self.pressedBackground,
                borderColor: self.isSelected ? Color.clear : AF.neutral(300)
            )
        )
        .accessibilityAddTraits(self.isSelected ? [.isSelected] : [])
    }

    private var fontSize: CGFloat {
        self.size == .small ? 13 : 14
    }

    private var verticalPadding: CGFloat {
        self.size == .small ? 6 : 9
    }

    private var horizontalPadding: CGFloat {
        self.size == .small ? 13 : 14
    }

    private var background: Color {
        guard self.isSelected else { return .clear }
        return switch self.style {
        case .accent: AF.accent
        case .sage: AF.accent2(200)
        }
    }

    private var pressedBackground: Color {
        guard self.isSelected else { return AF.neutral(200) }
        return switch self.style {
        case .accent: AF.accentPressed
        case .sage: AF.accent2(300)
        }
    }

    private var foreground: Color {
        guard self.isSelected else { return AF.neutral(700) }
        return switch self.style {
        case .accent: AF.onAccent
        case .sage: AF.accent2(800)
        }
    }
}
