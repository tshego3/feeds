import Foundation

/// Top-level navigation tabs matching the design system's sidebar.
enum AppTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case unread = "Unread"
    case bookmarks = "Bookmarks"
    case discover = "Discover"
    case search = "Search"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "dot.radiowaves.up.forward"
        case .unread: return "envelope.badge"
        case .bookmarks: return "bookmark"
        case .discover: return "safari"
        case .search: return "magnifyingglass"
        case .settings: return "gearshape"
        }
    }
}
