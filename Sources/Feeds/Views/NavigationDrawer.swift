import SwiftUI

/// Desktop sidebar navigation drawer matching the "Monolithic Clarity" design.
/// Features the "feeds" wordmark, nav items with active state indicator,
/// and a scrollable feed list with grouped categories below.
struct NavigationDrawer: View {
    @Binding var selectedTab: AppTab
    @ObservedObject var viewModel: FeedViewModel
    @State private var expandedGroups: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Wordmark
            Text("feeds")
                .font(.system(size: 32, weight: .bold))
                .tracking(-1.5)
                .foregroundColor(Theme.primary)
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 24)

            // Primary nav items
            ForEach(AppTab.allCases.filter { $0 != .settings }) { tab in
                navItem(tab)
            }

            // Feed list divider
            Rectangle()
                .fill(Theme.outlineVariant.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            // Feeds label
            Text("FEEDS")
                .labelXSmall()
                .foregroundColor(Theme.onSurfaceVariant.opacity(0.5))
                .tracking(2)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

            // Scrollable feed list with categories
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.menuItems) { menuItem in
                        switch menuItem {
                        case .single(let feed):
                            feedRow(feed)
                        case .group(let id, let title, let feeds):
                            groupSection(id: id, title: title, feeds: feeds)
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            // Divider before settings
            Rectangle()
                .fill(Theme.outlineVariant.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 16)

            navItem(.settings)
                .padding(.bottom, 16)
        }
        .frame(width: 272)
        .background(Theme.surfaceContainer)
    }

    // MARK: - Nav Item

    private func navItem(_ tab: AppTab) -> some View {
        let isActive = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 16) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20))
                Text(tab.rawValue)
                    .labelSmall()
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .foregroundColor(isActive ? Theme.primary : Theme.onSurfaceVariant)
            .background(isActive ? Theme.secondaryContainer : Color.clear)
            .overlay(
                isActive
                    ? Rectangle()
                        .fill(Theme.primary)
                        .frame(width: 2)
                    : nil,
                alignment: .leading
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }

    // MARK: - Feed List

    private func feedRow(_ feed: RssFeedModel) -> some View {
        let isSelected = viewModel.selectedFeedId == feed.id
        return Button {
            selectedTab = .home
            viewModel.selectedFeedId = feed.id
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(isSelected ? Theme.primary : Theme.surfaceContainerHigh)
                    .frame(width: 6, height: 6)
                Text(feed.title)
                    .labelSmall()
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? Theme.primary : Theme.onSurfaceVariant)
            .background(isSelected ? Theme.secondaryContainer.opacity(0.3) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    private func groupSection(id: String, title: String, feeds: [RssFeedModel]) -> some View {
        let isExpanded = expandedGroups.contains(id)
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                if isExpanded {
                    expandedGroups.remove(id)
                } else {
                    expandedGroups.insert(id)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: 12)
                    Text(title)
                        .labelSmall()
                    Spacer()
                    Text("\(feeds.count)")
                        .labelXSmall()
                        .foregroundColor(Theme.outline)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .foregroundColor(Theme.onSurfaceVariant)
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(feeds) { feed in
                    feedRow(feed)
                        .padding(.leading, 12)
                }
            }
        }
    }
}
