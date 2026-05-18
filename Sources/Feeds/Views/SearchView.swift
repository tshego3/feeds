import SwiftUI

/// Search view — search articles and sources with filtering.
/// Matches search/code.html design.
struct SearchView: View {
    @ObservedObject var viewModel: FeedViewModel
    @State private var searchText = ""
    @State private var recentSearches: [String] = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
    @Environment(\.themeColors) private var theme

    private static let maxRecentSearches = 10

    private func addRecentSearch(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        recentSearches.removeAll { $0 == trimmed }
        recentSearches.insert(trimmed, at: 0)
        if recentSearches.count > Self.maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(Self.maxRecentSearches))
        }
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }

    private func clearRecentSearches() {
        recentSearches.removeAll()
        UserDefaults.standard.removeObject(forKey: "recentSearches")
    }

    private func removeRecentSearch(_ term: String) {
        recentSearches.removeAll { $0 == term }
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }

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
        .background(theme.background)
    }

    // MARK: - Search Header

    private var searchHeader: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Search")
                .headlineLarge()
                .foregroundColor(theme.primary)

            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(theme.outline)
                TextField("Search articles, sources, or topics...", text: $searchText)
                    .foregroundColor(theme.onSurface)
                    .bodyLarge()
                    .onSubmit { addRecentSearch(searchText) }
            }
            .padding(20)
            .background(theme.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.outlineVariant, lineWidth: 1)
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
                    .foregroundColor(theme.outline)
                    .textCase(.uppercase)
                Spacer()
                Button("CLEAR ALL") {
                    clearRecentSearches()
                }
                .labelXSmall()
                .foregroundColor(theme.primary)
                .buttonStyle(.plain)
            }

            FlowLayout(spacing: 8) {
                ForEach(recentSearches, id: \.self) { term in
                    HStack(spacing: 6) {
                        Text(term)
                            .labelXSmall()
                        Button {
                            removeRecentSearch(term)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundColor(theme.onSurface)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(theme.secondaryContainer.opacity(0.3))
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

    // MARK: - Results

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("ARTICLES")
                    .labelSmall()
                    .foregroundColor(theme.outline)
                    .textCase(.uppercase)
                Spacer()
                HStack(spacing: 4) {
                    Text("Sort by:")
                        .labelXSmall()
                        .foregroundColor(theme.onSurfaceVariant)
                    Text("Relevance")
                        .labelXSmall()
                        .foregroundColor(theme.primary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(theme.outline)
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
                        .foregroundColor(theme.onSurfaceVariant)
                    Text(error)
                        .bodyMedium()
                        .foregroundColor(theme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(theme.onSurfaceVariant)
                    Text(searchText.isEmpty
                        ? "Search your feed articles by title or content."
                        : "No results found for \"\(searchText)\".")
                        .bodyMedium()
                        .foregroundColor(theme.onSurfaceVariant)
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
                        .foregroundColor(theme.outline)
                }

                Text(item.title)
                    .headlineMedium()
                    .foregroundColor(theme.primary)
                    .lineLimit(2)

                Text(item.plainDescription)
                    .bodyMedium()
                    .foregroundColor(theme.onSurfaceVariant)
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
                .fill(theme.outlineVariant.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 24)
        }
    }
}
