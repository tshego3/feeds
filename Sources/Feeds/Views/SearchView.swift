import SwiftUI

/// Search view — search articles and sources with filtering.
/// Matches search/code.html design.
struct SearchView: View {
    @ObservedObject var viewModel: FeedViewModel
    @State private var searchText = ""
    // TODO: Load recent searches from persistent storage (UserDefaults or SearchHistoryService)
    @State private var recentSearches: [String] = []

    private var filteredItems: [FeedItem] {
        guard !searchText.isEmpty else { return viewModel.feedItems }
        let query = searchText.lowercased()
        return viewModel.feedItems.filter {
            $0.title.lowercased().contains(query) ||
            $0.description.lowercased().contains(query)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                searchHeader
                recentSearchesSection
                resultsSection
            }
            .padding(.bottom, 80)
        }
        .background(Theme.background)
    }

    // MARK: - Search Header

    private var searchHeader: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Search")
                .headlineLarge()
                .foregroundColor(Theme.primary)

            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.outline)
                TextField("Search articles, sources, or topics...", text: $searchText)
                    .foregroundColor(Theme.onSurface)
                    .bodyLarge()
            }
            .padding(20)
            .background(Theme.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.outlineVariant, lineWidth: 1)
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }

    // MARK: - Recent Searches

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT SEARCHES")
                    .labelSmall()
                    .foregroundColor(Theme.outline)
                    .textCase(.uppercase)
                Spacer()
                Button("CLEAR ALL") {
                    recentSearches.removeAll()
                }
                .labelXSmall()
                .foregroundColor(Theme.primary)
                .buttonStyle(.plain)
            }

            FlowLayout(spacing: 8) {
                ForEach(recentSearches, id: \.self) { term in
                    HStack(spacing: 6) {
                        Text(term)
                            .labelXSmall()
                        Button {
                            recentSearches.removeAll { $0 == term }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundColor(Theme.onSurface)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Theme.secondaryContainer.opacity(0.3))
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

    // MARK: - Results

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("ARTICLES")
                    .labelSmall()
                    .foregroundColor(Theme.outline)
                    .textCase(.uppercase)
                Spacer()
                HStack(spacing: 4) {
                    Text("Sort by:")
                        .labelXSmall()
                        .foregroundColor(Theme.onSurfaceVariant)
                    Text("Relevance")
                        .labelXSmall()
                        .foregroundColor(Theme.primary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.outline)
                }
            }
            .padding(.horizontal, 24)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.onSurfaceVariant)
                    Text(error)
                        .bodyMedium()
                        .foregroundColor(Theme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.onSurfaceVariant)
                    Text(searchText.isEmpty
                        ? "Search your feed articles by title or content."
                        : "No results found for \"\(searchText)\".")
                        .bodyMedium()
                        .foregroundColor(Theme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(filteredItems) { item in
                        NavigationLink(value: item) {
                            searchResultRow(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func searchResultRow(_ item: FeedItem) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(Helpers.formatDate(item.pubDate))
                        .labelXSmall()
                        .foregroundColor(Theme.outline)
                }

                Text(item.title)
                    .headlineMedium()
                    .foregroundColor(Theme.primary)
                    .lineLimit(2)

                Text(item.description)
                    .bodyMedium()
                    .foregroundColor(Theme.onSurfaceVariant)
                    .lineLimit(2)
            }

            Spacer()

            if let url = item.displayImage {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 72)
                            .saturation(0)
                            .opacity(0.6)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    default:
                        EmptyView()
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.outlineVariant.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 24)
        }
    }
}
