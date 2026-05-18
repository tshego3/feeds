import SwiftUI

/// Dashboard view — Bento-grid feed layout with featured article and sidebar cards.
/// Matches the dashboard/code.html design.
struct DashboardView: View {
    @ObservedObject var viewModel: FeedViewModel
    @Environment(\.themeColors) var theme
    var filterUnreadOnly: Bool = false

    private var displayItems: [FeedItem] {
        filterUnreadOnly ? viewModel.unreadItems : viewModel.feedItems
    }

    private var hasDisplayItems: Bool { !displayItems.isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                contentSection
            }
            .padding(.bottom, 80)
        }
        .refreshable {
            await viewModel.refreshFeed()
        }
        .background(theme.background)
    }

    // MARK: - Header

    private var headerTitle: String {
        guard !filterUnreadOnly else { return "Unread" }
        return viewModel.selectedFeed?.title ?? ""
    }

    private var headerSubtitle: String {
        if filterUnreadOnly {
            return "\(displayItems.count) UNREAD ARTICLES"
        }
        return "\(displayItems.count) ARTICLES"
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(headerTitle)
                .headlineLarge()
                .foregroundColor(theme.primary)

            Text(headerSubtitle)
                .labelXSmall()
                .foregroundColor(theme.onSurfaceVariant)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 32)
    }

    // MARK: - Content

    private var contentSection: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else if hasDisplayItems {
                bentoGrid
            } else {
                emptyState
            }
        }
    }

    // MARK: - Bento Grid

    private var bentoGrid: some View {
        let items = displayItems
        return LazyVStack(spacing: 24) {
            // Featured article (first item)
            if let featured = items.first {
                NavigationLink(value: featured) {
                    FeaturedArticleCard(item: featured)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
            }

            // Secondary row — 2-up or 3-up grid
            if items.count > 1 {
                let secondary = Array(items.dropFirst().prefix(6))
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                ], spacing: 16) {
                    ForEach(secondary) { item in
                        NavigationLink(value: item) {
                            ArticleCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: 720)
                .padding(.horizontal, 24)
            }

            // Remaining items in single column
            if items.count > 7 {
                ForEach(Array(items.dropFirst(7))) { item in
                    NavigationLink(value: item) {
                        CompactArticleRow(item: item)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: 720)
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    // MARK: - States

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(theme.onSurfaceVariant)
            Text(message)
                .bodyMedium()
                .foregroundColor(theme.onSurfaceVariant)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task {
                    if let feed = viewModel.selectedFeed {
                        await viewModel.selectFeed(feed)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(theme.primary)
            .foregroundColor(theme.onPrimary)
            .clipShape(Capsule())
            .labelSmall()
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(theme.onSurfaceVariant)
            Text("No articles found.")
                .headlineMedium()
                .foregroundColor(theme.primary)
            Text(filterUnreadOnly
                ? "You're all caught up! No unread articles."
                : "Select a feed from the sidebar to get started.")
                .bodyMedium()
                .foregroundColor(theme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

// MARK: - Featured Article Card

struct FeaturedArticleCard: View {
    let item: FeedItem
    @EnvironmentObject var bookmarks: BookmarkViewModel
    @Environment(\.themeColors) var theme

    private var hasImage: Bool { item.displayImage != nil }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Image
            if let url = item.displayImage {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 380)
                    .overlay(
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                fallbackImage
                            case .empty:
                                ProgressView()
                            @unknown default:
                                EmptyView()
                            }
                        }
                    )
                    .clipped()
                    .saturation(0)
            } else {
                theme.surfaceContainerLow
            }

            // Gradient overlay
            LinearGradient(
                colors: [theme.background, theme.background.opacity(0.4), .clear],
                startPoint: .bottom,
                endPoint: .top
            )

            // Content overlay
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 8, height: 8)
                    Text(Helpers.formatDate(item.pubDate))
                        .labelXSmall()
                        .foregroundColor(theme.onSurfaceVariant)
                }

                Text(item.title)
                    .headlineLarge()
                    .foregroundColor(theme.primary)
                    .lineLimit(3)

                Text(item.plainDescription)
                    .bodyLarge()
                    .foregroundColor(theme.onSurfaceVariant)
                    .lineLimit(2)

                HStack {
                    if let url = URL(string: item.link) {
                        Link(destination: url) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14))
                                Text("Read Article")
                                    .labelSmall()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(theme.primary)
                            .foregroundColor(theme.onPrimary)
                            .clipShape(Capsule())
                        }
                    }
                    Spacer()
                    Button { bookmarks.toggle(item) } label: {
                        Image(systemName: bookmarks.isBookmarked(item) ? "bookmark.fill" : "bookmark")
                            .foregroundColor(bookmarks.isBookmarked(item) ? theme.primary : theme.onSurfaceVariant)
                    }
                    .buttonStyle(.plain)
                    if let url = URL(string: item.link) {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(24)
        }
        .frame(height: hasImage ? 380 : nil)
        .frame(minHeight: hasImage ? nil : 200)
        .frame(maxWidth: 720)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.outlineVariant, lineWidth: 1)
        )
    }

    private var fallbackImage: some View {
        Rectangle()
            .fill(theme.surfaceContainerLow)
            .frame(maxWidth: .infinity)
            .frame(height: 380)
    }
}

// MARK: - Article Card

struct ArticleCard: View {
    let item: FeedItem
    @EnvironmentObject var bookmarks: BookmarkViewModel
    @EnvironmentObject var modelManager: ModelManagerViewModel
    @Environment(\.themeColors) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail
            if let url = item.displayImage {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .overlay(
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .saturation(0)
                            default:
                                EmptyView()
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Text(Helpers.formatDate(item.pubDate))
                .labelXSmall()
                .foregroundColor(theme.onSurfaceVariant)
                .textCase(.uppercase)

            Text(item.title)
                .headlineMedium()
                .foregroundColor(theme.primary)
                .lineLimit(3)

            Text(item.plainDescription)
                .bodyMedium()
                .foregroundColor(theme.onSurfaceVariant)
                .lineLimit(2)

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                    Text(modelManager.isModelLoaded ? "AI Summary" : "Summary")
                        .labelXSmall()
                }
                .foregroundColor(modelManager.isModelLoaded ? theme.primary : theme.onSurfaceVariant)

                Spacer()

                Button { bookmarks.toggle(item) } label: {
                    Image(systemName: bookmarks.isBookmarked(item) ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16))
                        .foregroundColor(bookmarks.isBookmarked(item) ? theme.primary : theme.onSurfaceVariant)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(theme.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.outlineVariant, lineWidth: 1)
        )
    }
}

// MARK: - Compact Article Row

struct CompactArticleRow: View {
    let item: FeedItem
    @Environment(\.themeColors) var theme

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(Helpers.formatDate(item.pubDate))
                    .labelXSmall()
                    .foregroundColor(theme.onSurfaceVariant)

                Text(item.title)
                    .headlineMedium()
                    .foregroundColor(theme.primary)
                    .lineLimit(2)

                Text(item.plainDescription)
                    .bodyMedium()
                    .foregroundColor(theme.onSurfaceVariant)
                    .lineLimit(1)
            }

            Spacer()

            if let url = item.displayImage {
                Color.clear
                    .frame(width: 80, height: 60)
                    .overlay(
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .saturation(0)
                                    .opacity(0.7)
                            default:
                                EmptyView()
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(theme.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.outlineVariant.opacity(0.3), lineWidth: 1)
        )
    }
}
