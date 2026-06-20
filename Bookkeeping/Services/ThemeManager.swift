import SwiftUI

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var localizedName: String {
        switch self {
        case .system: return NSLocalizedString("theme_system", comment: "")
        case .light: return NSLocalizedString("theme_light", comment: "")
        case .dark: return NSLocalizedString("theme_dark", comment: "")
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage("theme") var currentTheme: AppTheme = .system
    
    var colorScheme: ColorScheme? {
        currentTheme.colorScheme
    }
}
