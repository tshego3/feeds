import SwiftUI
#if canImport(Feeds)
import Feeds
#endif

private typealias AppRootView = FeedsRootView
private typealias AppDelegate = FeedsAppDelegate

/// The Darwin entry point — loads the shared FeedsRootView from the Feeds module.
@main struct AppMain: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                AppDelegate.shared.onResume()
            case .inactive:
                AppDelegate.shared.onPause()
            case .background:
                AppDelegate.shared.onStop()
            @unknown default:
                break
            }
        }
    }
}
