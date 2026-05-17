import SwiftUI

/// Feed Explorer / Discover view — browse and follow new sources.
/// Matches feed_explorer/code.html design.
struct ExploreView: View {
    @State private var searchText = ""
    @ObservedObject var viewModel: FeedViewModel

    private var allDiscoverFeeds: [DiscoverFeed] {
        viewModel.menuItems.flatMap { item -> [DiscoverFeed] in
            switch item {
            case .single(let feed):
                return [DiscoverFeed(id: feed.id, name: feed.title, category: "General")]
            case .group(_, let title, let feeds):
                return feeds.map { DiscoverFeed(id: $0.id, name: $0.title, category: title) }
            }
        }
    }

    private var filteredFeeds: [DiscoverFeed] {
        guard !searchText.isEmpty else { return allDiscoverFeeds }
        let query = searchText.lowercased()
        return allDiscoverFeeds.filter {
            $0.name.lowercased().contains(query) || $0.category.lowercased().contains(query)
        }
    }

    private var groupedByCategory: [(String, [DiscoverFeed])] {
        let feeds = filteredFeeds
        var seen: [String] = []
        var grouped: [String: [DiscoverFeed]] = [:]
        for feed in feeds {
            if !seen.contains(feed.category) { seen.append(feed.category) }
            grouped[feed.category, default: []].append(feed)
        }
        return seen.compactMap { key in grouped[key].map { (key, $0) } }
    }

    private var categories: [String] {
        viewModel.menuItems.compactMap { item -> String? in
            guard case .group(_, let title, _) = item else { return nil }
            return title
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 48) {
                headerSection
                if let first = groupedByCategory.first {
                    suggestedSection(feed: first.1.first)
                }
                categoryLists
                popularCategories
            }
            .padding(.bottom, 80)
        }
        .background(Theme.background)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Explore")
                    .headlineLarge()
                    .foregroundColor(Theme.primary)

                Text("Find and follow the best sources across the web. Curate your focus with precision.")
                    .bodyMedium()
                    .foregroundColor(Theme.onSurfaceVariant)
            }

            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.onSurfaceVariant)
                TextField("Search by name, URL, or topic...", text: $searchText)
                    .foregroundColor(Theme.onSurface)
                    .bodyMedium()
            }
            .padding(16)
            .background(Theme.surfaceContainerLow)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.outlineVariant, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }

    // MARK: - Suggested Section

    private func suggestedSection(feed: DiscoverFeed?) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Suggested for you")
                    .headlineMedium()
                    .foregroundColor(Theme.primary)
                Spacer()
            }
            .padding(.horizontal, 24)

            if let feed {
                // Featured card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Text(feed.category.uppercased())
                            .labelXSmall()
                            .foregroundColor(Theme.onPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    Text(feed.name)
                        .headlineMedium()
                        .foregroundColor(Theme.primary)

                    Text(feed.description.isEmpty ? "Follow this source to see articles in your feed." : feed.description)
                        .bodyMedium()
                        .foregroundColor(Theme.onSurfaceVariant)
                        .lineLimit(2)
                }
                .padding(24)
                .frame(maxWidth: .infinity, minHeight: 200, alignment: .bottomLeading)
                .background(Theme.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.outlineVariant, lineWidth: 1)
                )
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Category Lists

    private var categoryLists: some View {
        VStack(spacing: 48) {
            ForEach(groupedByCategory, id: \.0) { category, feeds in
                categorySection(title: category, feeds: feeds)
            }
        }
        .padding(.horizontal, 24)
    }

    private func categorySection(title: String, feeds: [DiscoverFeed]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text(title)
                    .headlineMedium()
                    .foregroundColor(Theme.primary)
                Spacer()
                Text("\(feeds.count)")
                    .labelXSmall()
                    .foregroundColor(Theme.outline)
            }
            .padding(.bottom, 4)

            Rectangle()
                .fill(Theme.outlineVariant)
                .frame(height: 1)

            ForEach(feeds) { feed in
                feedRow(feed)
            }
        }
    }

    private func feedRow(_ feed: DiscoverFeed) -> some View {
        HStack(spacing: 16) {
            Text(feed.initials)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.primary)
                .frame(width: 40, height: 40)
                .background(Theme.surfaceContainer)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(feed.name)
                    .labelSmall()
                    .foregroundColor(Theme.primary)
                Text(feed.description)
                    .labelXSmall()
                    .foregroundColor(Theme.onSurfaceVariant)
            }

            Spacer()

            Button("FOLLOW") { }
                .labelXSmall()
                .foregroundColor(Theme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Theme.primary, lineWidth: 1)
                )
                .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Popular Categories

    private var popularCategories: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Popular Categories")
                .headlineMedium()
                .foregroundColor(Theme.primary)

            FlowLayout(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Text(category)
                        .labelSmall()
                        .foregroundColor(Theme.onSurface)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Theme.surfaceContainer)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Theme.outlineVariant, lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Flow Layout (wrapping chip layout)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
