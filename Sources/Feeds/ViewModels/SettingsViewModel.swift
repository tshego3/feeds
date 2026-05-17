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
            Theme.apply(selectedTheme)
        }
    }

    init() {
        self.autoRefresh = UserDefaults.standard.object(forKey: "autoRefresh") as? Bool ?? false
        self.markReadOnScroll = UserDefaults.standard.object(forKey: "markReadOnScroll") as? Bool ?? true
        self.selectedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? "Dark"
        Theme.apply(self.selectedTheme)
    }
}
