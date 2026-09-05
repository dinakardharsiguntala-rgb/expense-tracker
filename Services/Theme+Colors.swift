import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension Color {
    public static var appBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .systemGroupedBackground)
        #else
        return Color(white: 0.95)
        #endif
    }

    public static var appSecondaryBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #else
        return Color.white
        #endif
    }

    public static var appTertiaryBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .tertiarySystemGroupedBackground)
        #else
        return Color(white: 0.90)
        #endif
    }

    public static var appGray5: Color {
        #if canImport(UIKit)
        return Color(uiColor: .systemGray5)
        #else
        return Color.gray.opacity(0.2)
        #endif
    }
}

