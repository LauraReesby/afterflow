import SwiftUI

/// Design tokens for the "Organic" design system.
/// Colors resolve through Assets.xcassets (`Theme/` and `Treatment/` namespaces),
/// where light and dark values are both defined — views never branch on color scheme.
enum AF {
    // MARK: Roles

    static let bg = Color("Theme/bg")
    static let text = Color("Theme/text")
    /// Glyphs and labels sitting on an accent fill: cream in light, dark ink in dark.
    static let onAccent = Color("Theme/onAccent")
    static let segmentedTrack = Color("Theme/segmentedTrack")
    static let segmentedSelected = Color("Theme/segmentedSelected")
    static let segmentedBorder = Color("Theme/segmentedBorder")
    static let accentPressed = Color("Theme/accentPressed")

    // MARK: Ramps

    /// Base terracotta accent (#c67139); same in both modes.
    static let accent = Color("Theme/accent")
    /// Base sage second accent (#7a8a5e); same in both modes.
    static let accent2 = Color("Theme/accent2")

    /// Neutral ramp step (100...900). Steps are surface-relative: 100 is always
    /// "card on ground", 900 is always "ink" — dark values are baked in the catalog.
    static func neutral(_ step: Int) -> Color {
        Color("Theme/neutral\(step)")
    }

    /// Terracotta ramp step (100...900).
    static func accent(_ step: Int) -> Color {
        Color("Theme/accent\(step)")
    }

    /// Sage ramp step (100...900).
    static func accent2(_ step: Int) -> Color {
        Color("Theme/accent2-\(step)")
    }
}

// MARK: - Typography

extension Font {
    /// Caprasimo display face. Weight 400 only — hierarchy is size and space, never boldness.
    static func afterflowDisplay(_ size: CGFloat) -> Font {
        .custom("Caprasimo-Regular", size: size, relativeTo: displayTextStyle(for: size))
    }

    /// Figtree body/UI face.
    static func afterflowBody(_ size: CGFloat, weight: AFBodyWeight = .regular) -> Font {
        .custom(weight.postScriptName, size: size, relativeTo: bodyTextStyle(for: size))
    }

    private static func displayTextStyle(for size: CGFloat) -> TextStyle {
        switch size {
        case 34...: .largeTitle
        case 28 ..< 34: .title
        case 24 ..< 28: .title2
        default: .title3
        }
    }

    private static func bodyTextStyle(for size: CGFloat) -> TextStyle {
        switch size {
        case 16...: .body
        case 15 ..< 16: .subheadline
        case 13 ..< 15: .footnote
        case 12 ..< 13: .caption
        default: .caption2
        }
    }
}

enum AFBodyWeight {
    case regular
    case semibold
    case bold

    var postScriptName: String {
        switch self {
        case .regular: "Figtree-Regular"
        case .semibold: "Figtree-SemiBold"
        case .bold: "Figtree-Bold"
        }
    }
}

// MARK: - Kicker (section label) style

private struct KickerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.afterflowBody(12, weight: .semibold))
            .tracking(0.96)
            .textCase(.uppercase)
            .foregroundStyle(AF.neutral(600))
    }
}

extension View {
    /// Section-label style: Figtree 12/600, 0.08em tracking, uppercase, neutral-600.
    func kicker() -> some View {
        modifier(KickerModifier())
    }
}

// MARK: - Shadows

enum AFShadow {
    case sm
    case md
    case lg
}

extension View {
    /// Token shadows on the warm ink color (#2e2b25). CSS blur ≈ 2× SwiftUI radius.
    func afShadow(_ level: AFShadow) -> some View {
        let ink = Color(red: 0x2E / 255, green: 0x2B / 255, blue: 0x25 / 255)
        return switch level {
        case .sm: shadow(color: ink.opacity(0.14), radius: 1, x: 0, y: 1)
        case .md: shadow(color: ink.opacity(0.16), radius: 5, x: 0, y: 3)
        case .lg: shadow(color: ink.opacity(0.22), radius: 16, x: 0, y: 12)
        }
    }
}

// MARK: - Button styles
//
// Pressed states step one ramp level ("accent" → "accentPressed",
// tinted surfaces → next ramp step) — never the system default.

/// Capsule-filled button; the fill lives in the style so pressing can swap it.
struct AFCapsuleButtonStyle: ButtonStyle {
    let fill: Color
    let pressedFill: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Capsule().fill(configuration.isPressed ? self.pressedFill : self.fill))
            .animation(
                .easeInOut(duration: DesignConstants.Animation.quickDuration),
                value: configuration.isPressed
            )
    }
}

/// Circle-filled button (the floating Add button).
struct AFCircleButtonStyle: ButtonStyle {
    let fill: Color
    let pressedFill: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Circle().fill(configuration.isPressed ? self.pressedFill : self.fill))
            .animation(
                .easeInOut(duration: DesignConstants.Animation.quickDuration),
                value: configuration.isPressed
            )
    }
}

/// Chip button: fill plus a hairline border for the unselected state.
struct AFChipButtonStyle: ButtonStyle {
    let fill: Color
    let pressedFill: Color
    let borderColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Capsule().fill(configuration.isPressed ? self.pressedFill : self.fill))
            .overlay(Capsule().strokeBorder(self.borderColor, lineWidth: 1))
            .animation(
                .easeInOut(duration: DesignConstants.Animation.quickDuration),
                value: configuration.isPressed
            )
    }
}

/// Text-link button (Done, Clear, Add more): dims while pressed.
struct AFLinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1)
    }
}
