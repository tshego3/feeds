import SwiftUI

/// Feed Explorer / Discover view — browse and follow new sources.
/// Matches feed_explorer/code.html design.
struct ExploreView: View {
    @State private var searchText = ""
    @ObservedObject var viewModel: FeedViewModel
    @Environment(\.themeColors) private var theme

    private var groupedByCategory: [(String, [DiscoverFeed])] {
        viewModel.groupedDiscoverFeeds(query: searchText)
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
        .background(theme.background)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Explore")
                    .headlineLarge()
                    .foregroundColor(theme.primary)

                Text("Find and follow the best sources across the web. Curate your focus with precision.")
                    .bodyMedium()
                    .foregroundColor(theme.onSurfaceVariant)
            }

            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(theme.onSurfaceVariant)
                TextField("Search by name, URL, or topic...", text: $searchText)
                    .foregroundColor(theme.onSurface)
                    .bodyMedium()
            }
            .padding(16)
            .background(theme.surfaceContainerLow)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.outlineVariant, lineWidth: 1)
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
                    .foregroundColor(theme.primary)
                Spacer()
            }
            .padding(.horizontal, 24)

            if let feed {
                // Featured card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Text(feed.category.uppercased())
                            .labelXSmall()
                            .foregroundColor(theme.onPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(theme.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    Text(feed.name)
                        .headlineMedium()
                        .foregroundColor(theme.primary)

                    Text(feed.description.isEmpty ? "Follow this source to see articles in your feed." : feed.description)
                        .bodyMedium()
                        .foregroundColor(theme.onSurfaceVariant)
                        .lineLimit(2)
                }
                .padding(24)
                .frame(maxWidth: .infinity, minHeight: 200, alignment: .bottomLeading)
                .background(theme.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.outlineVariant, lineWidth: 1)
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
                    .foregroundColor(theme.primary)
                Spacer()
                Text("\(feeds.count)")
                    .labelXSmall()
                    .foregroundColor(theme.outline)
            }
            .padding(.bottom, 4)

            Rectangle()
                .fill(theme.outlineVariant)
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
                .foregroundColor(theme.primary)
                .frame(width: 40, height: 40)
                .background(theme.surfaceContainer)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(feed.name)
                    .labelSmall()
                    .foregroundColor(theme.primary)
                Text(feed.description)
                    .labelXSmall()
                    .foregroundColor(theme.onSurfaceVariant)
            }

            Spacer()

            Button("FOLLOW") { }
                .labelXSmall()
                .foregroundColor(theme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(theme.primary, lineWidth: 1)
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
                .foregroundColor(theme.primary)

            FlowLayout(spacing: 8) {
                ForEach(viewModel.feedCategories, id: \.self) { category in
                    Text(category)
                        .labelSmall()
                        .foregroundColor(theme.onSurface)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(theme.surfaceContainer)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(theme.outlineVariant, lineWidth: 1)
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
