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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(bookmarkViewModel)
                .preferredColorScheme(settings.selectedTheme == "Light" ? .light : .dark)
        }
    }
}
