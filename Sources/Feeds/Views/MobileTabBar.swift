import SwiftUI

/// Mobile bottom navigation bar matching design system's glassmorphic tab bar.
struct MobileTabBar: View {
    @Binding var selectedTab: AppTab

    private let tabs: [AppTab] = [.home, .unread, .bookmarks, .search]

    var body: some View {
        HStack {
            ForEach(tabs) { tab in
                Spacer()
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 22))
                        Text(tabLabel(tab))
                            .labelXSmall()
                    }
                    .foregroundColor(selectedTab == tab ? Theme.primary : Theme.onSurfaceVariant)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        selectedTab == tab
                            ? Theme.secondaryContainer.opacity(0.5)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.outlineVariant)
                .frame(height: 1)
        }
    }

    private func tabLabel(_ tab: AppTab) -> String {
        switch tab {
        case .home: return "Home"
        case .unread: return "Unread"
        case .bookmarks: return "Saved"
        case .search: return "Search"
        default: return tab.rawValue
        }
    }
}
