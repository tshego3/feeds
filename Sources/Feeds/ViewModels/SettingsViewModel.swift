import Foundation

/// ViewModel for settings — persists user preferences via UserDefaults.
@MainActor
class SettingsViewModel: ObservableObject {

    private let defaults: UserDefaults

    @Published var autoRefresh: Bool = false {
        didSet { defaults.set(autoRefresh, forKey: "autoRefresh") }
    }

    @Published var markReadOnScroll: Bool = true {
        didSet { defaults.set(markReadOnScroll, forKey: "markReadOnScroll") }
    }

    @Published var showAISummaries: Bool = true {
        didSet { defaults.set(showAISummaries, forKey: "showAISummaries") }
    }

    @Published var selectedTheme: String = "Dark" {
        didSet {
            defaults.set(selectedTheme, forKey: "selectedTheme")
            guard selectedTheme != "Auto" else { return }
            themeColors = Theme.resolve(selectedTheme)
        }
    }

    @Published var themeColors: ThemeColors = .dark

    /// Cycles through Auto → Light → Dark → Monochrome → Auto.
    func cycleAppearance() {
        switch selectedTheme {
        case "Auto": selectedTheme = "Light"
        case "Light": selectedTheme = "Dark"
        case "Dark": selectedTheme = "Monochrome"
        default: selectedTheme = "Auto"
        }
    }

    /// Resolves the correct theme when in Auto mode based on device appearance.
    func applyAutoTheme(systemIsDark: Bool) {
        themeColors = systemIsDark ? .dark : .light
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.autoRefresh = defaults.object(forKey: "autoRefresh") as? Bool ?? false
        self.markReadOnScroll = defaults.object(forKey: "markReadOnScroll") as? Bool ?? true
        self.showAISummaries = defaults.object(forKey: "showAISummaries") as? Bool ?? true
        self.selectedTheme = defaults.string(forKey: "selectedTheme") ?? "Dark"
        guard self.selectedTheme != "Auto" else { return }
        self.themeColors = Theme.resolve(self.selectedTheme)
    }
}
