import SwiftUI
import SkipFuse

/// The shared root view for the app, loaded from platform-specific entry points.
/// On iOS: instantiated by Darwin/Sources/Main.swift
/// On Android: instantiated by Android/app/src/main/kotlin/Main.kt
/* SKIP @bridge */public struct FeedsRootView: View {
    @StateObject var settings = SettingsViewModel()
    @StateObject var bookmarkViewModel = BookmarkViewModel()
    @StateObject var modelManager = ModelManagerViewModel()
    @StateObject var imageResolver = ImageResolver()

    /* SKIP @bridge */public init() {}

    public var body: some View {
        FeedsContentWrapper()
            .environmentObject(settings)
            .environmentObject(bookmarkViewModel)
            .environmentObject(modelManager)
            .environmentObject(imageResolver)
    }
}

/// Wrapper view that syncs the device color scheme with the theme engine in Auto mode.
struct FeedsContentWrapper: View {
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var bookmarks: BookmarkViewModel
    @Environment(\.colorScheme) var systemColorScheme

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

/// Global application delegate for lifecycle events.
/* SKIP @bridge */public final class FeedsAppDelegate: Sendable {
    /* SKIP @bridge */public static let shared = FeedsAppDelegate()
    private init() {}

    /* SKIP @bridge */public func onInit() {}
    /* SKIP @bridge */public func onLaunch() {}
    /* SKIP @bridge */public func onResume() {}
    /* SKIP @bridge */public func onPause() {}
    /* SKIP @bridge */public func onStop() {}
    /* SKIP @bridge */public func onDestroy() {}
    /* SKIP @bridge */public func onLowMemory() {}
}
