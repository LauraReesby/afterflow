import Foundation
import SwiftUI

enum DesignConstants {
    enum Animation {
        static let standardDuration: TimeInterval = 0.3
        static let quickDuration: TimeInterval = 0.2
        static let springResponse: TimeInterval = 0.35
        static let springDampingFraction: CGFloat = 0.8
    }

    enum Shadow {
        static let standardOpacity: CGFloat = 0.1
        static let standardRadius: CGFloat = 8
        static let standardX: CGFloat = 0
        static let standardY: CGFloat = 2
        static let lightRadius: CGFloat = 4
        static let lightY: CGFloat = 1
    }

    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }

    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 10
        static let large: CGFloat = 16
        static let searchBar: CGFloat = 18
    }

    enum Opacity {
        static let ghost: CGFloat = 0.12
        static let faint: CGFloat = 0.15
        static let light: CGFloat = 0.25
        static let medium: CGFloat = 0.5
        static let subtle: CGFloat = 0.7
    }

    enum Testing {
        
        static let exportDelay: UInt64 = 300_000_000
        
        static let downloadPollingInterval: UInt64 = 200_000_000
    }
}
