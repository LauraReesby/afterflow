import SwiftUI

extension PsychedelicTreatmentType {
    /// Muted earth tones from the Organic design system (`Treatment/` asset namespace).
    /// Same values in light and dark mode.
    var accentColor: Color {
        switch self {
        case .ketamine: Color("Treatment/ketamine")
        case .psilocybin: Color("Treatment/psilocybin")
        case .lsd: Color("Treatment/lsd")
        case .mdma: Color("Treatment/mdma")
        case .dmt: Color("Treatment/dmt")
        case .ayahuasca: Color("Treatment/ayahuasca")
        case .mescaline: Color("Treatment/mescaline")
        case .cannabis: Color("Treatment/cannabis")
        case .other: Color("Treatment/other")
        }
    }

    var initials: String {
        switch self {
        case .ketamine: "K"
        case .psilocybin: "P"
        case .lsd: "L"
        case .mdma: "MD"
        case .dmt: "D"
        case .ayahuasca: "A"
        case .mescaline: "ME"
        case .cannabis: "C"
        case .other: "O"
        }
    }
}
