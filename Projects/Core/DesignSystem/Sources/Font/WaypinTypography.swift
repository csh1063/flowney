import SwiftUI
import UIKit

public enum WaypinFont {
    public static let screenTitle = Font.custom("GothicA1-SemiBold", size: 22, relativeTo: .title2)
    public static let sectionHeader = Font.custom("GothicA1-SemiBold", size: 17, relativeTo: .headline)
    public static let body = Font.custom("GothicA1-Regular", size: 16, relativeTo: .body)
    public static let bodyEmphasis = Font.custom("GothicA1-SemiBold", size: 16, relativeTo: .body)
    public static let caption = Font.custom("GothicA1-Regular", size: 12, relativeTo: .caption)
    public static let captionEmphasis = Font.custom("GothicA1-SemiBold", size: 11, relativeTo: .caption2)
    public static let numeric = Font.custom("GothicA1-SemiBold", size: 16, relativeTo: .body)

    /// SwiftUI's `.font()` environment modifier doesn't reach UIKit-backed controls
    /// like `.pickerStyle(.segmented)` — they need a UIAppearance proxy instead.
    public static func applyUIKitAppearance() {
        let segmentFont = UIFont(name: "GothicA1-SemiBold", size: 13) ?? .systemFont(ofSize: 13, weight: .semibold)
        UISegmentedControl.appearance().setTitleTextAttributes([.font: segmentFont], for: .normal)
    }
}
