import Foundation

/// ViewModel for settings — persists user preferences via UserDefaults.
@MainActor
class SettingsViewModel: ObservableObject {

    @Published var autoRefresh: Bool = false {
        didSet { UserDefaults.standard.set(autoRefresh, forKey: "autoRefresh") }
    }

    @Published var markReadOnScroll: Bool = true {
        didSet { UserDefaults.standard.set(markReadOnScroll, forKey: "markReadOnScroll") }
    }

    @Published var selectedTheme: String = "Dark" {
        didSet {
            UserDefaults.standard.set(selectedTheme, forKey: "selectedTheme")
            guard selectedTheme != "Auto" else { return }
            Theme.apply(selectedTheme)
        }
    }

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
        Theme.apply(systemIsDark ? "Dark" : "Light")
    }

    init() {
        self.autoRefresh = UserDefaults.standard.object(forKey: "autoRefresh") as? Bool ?? false
        self.markReadOnScroll = UserDefaults.standard.object(forKey: "markReadOnScroll") as? Bool ?? true
        self.selectedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? "Dark"
        guard self.selectedTheme != "Auto" else { return }
        Theme.apply(self.selectedTheme)
    }
}
