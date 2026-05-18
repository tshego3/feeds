// FeedsApp.swift — The app entry point.
//
// In C#: this is like Program.cs with "static void Main()" or a top-level statement file.
// Swift uses SwiftUI's @main attribute (like [STAThread] + Application.Run in WPF/WinUI).

// "import" = "using" in C#. SwiftUI ≈ WPF/MAUI — a declarative UI framework.
import SwiftUI

// @main marks the app entry point (C#: static void Main).
// "struct" in Swift is a value type, just like in C#.
// Conforming to "App" protocol ≈ implementing an interface (": IApp" in C# terms).
// Swift protocols = C# interfaces — they define a contract.
@main
struct FeedsApp: App {
    @StateObject private var settings = SettingsViewModel()
    @StateObject private var bookmarkViewModel = BookmarkViewModel()
    @StateObject private var modelManager = ModelManagerViewModel()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(settings)
                .environmentObject(bookmarkViewModel)
                .environmentObject(modelManager)
        }
    }
}

/// Wrapper view that syncs the device color scheme with the theme engine in Auto mode.
private struct AppRootView: View {
    @EnvironmentObject private var settings: SettingsViewModel
    @EnvironmentObject private var bookmarks: BookmarkViewModel
    @Environment(\.colorScheme) private var systemColorScheme

    private var preferredScheme: ColorScheme? {
        switch settings.selectedTheme {
        case "Auto": return nil
        case "Light": return .light
        default: return .dark
        }
    }

    var body: some View {
        ContentView()
            .task { await bookmarks.loadBookmarks() }
            .preferredColorScheme(preferredScheme)
            .environment(\.themeColors, settings.themeColors)
            .onChange(of: systemColorScheme) { _, newScheme in
                guard settings.selectedTheme == "Auto" else { return }
                settings.applyAutoTheme(systemIsDark: newScheme == .dark)
            }
            .onChange(of: settings.selectedTheme) { _, newTheme in
                guard newTheme == "Auto" else { return }
                settings.applyAutoTheme(systemIsDark: systemColorScheme == .dark)
            }
            .onAppear {
                guard settings.selectedTheme == "Auto" else { return }
                settings.applyAutoTheme(systemIsDark: systemColorScheme == .dark)
            }
    }
}
