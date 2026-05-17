import SwiftUI

/// Saved/Bookmarked articles view with tag filters and asymmetric grid.
/// Matches saved_articles/code.html design.
struct SavedArticlesView: View {
    @EnvironmentObject private var bookmarks: BookmarkViewModel
    @State private var selectedTag = "#all"
    @Environment(\.themeColors) private var theme

    // TODO: Replace hardcoded tags with dynamic tags derived from saved articles
    private let tags = ["#all", "#readlater", "#research", "#design", "#tech"]

    private var filteredArticles: [SavedArticle] {
        bookmarks.articles(for: selectedTag)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                articlesList
            }
            .padding(.bottom, 80)
        }
        .background(theme.background)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Saved")
                .headlineLarge()
                .foregroundColor(theme.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Button {
                            selectedTag = tag
                        } label: {
                            Text(tag)
                                .labelXSmall()
                                .foregroundColor(selectedTag == tag ? theme.onPrimary : theme.onSurfaceVariant)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedTag == tag ? theme.primary : theme.surfaceContainerHigh)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 24)
    }

    // MARK: - Articles List

    private var articlesList: some View {
        Group {
            if filteredArticles.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(filteredArticles) { article in
                        savedArticleCard(article)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark")
                .font(.system(size: 40))
                .foregroundColor(theme.onSurfaceVariant)
            Text("No saved articles yet.")
                .headlineMedium()
                .foregroundColor(theme.primary)
            Text("Bookmark articles from your feeds to save them here for later reading.")
                .bodyMedium()
                .foregroundColor(theme.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    private func savedArticleCard(_ article: SavedArticle) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(article.source.uppercased())
                    .labelXSmall()
                    .foregroundColor(theme.onSurfaceVariant)
                    .tracking(1)
                Spacer()
                Button { bookmarks.remove(article) } label: {
                    Image(systemName: "bookmark.slash")
                        .foregroundColor(theme.onSurfaceVariant)
                }
                .buttonStyle(.plain)
            }

            Text(article.title)
                .headlineMedium()
                .foregroundColor(theme.primary)
                .lineLimit(2)

            if !article.description.isEmpty {
                Text(article.description)
                    .bodyMedium()
                    .foregroundColor(theme.onSurfaceVariant)
                    .lineLimit(3)
            }

            HStack(spacing: 12) {
                Text("#\(article.tag)")
                    .labelXSmall()
                    .foregroundColor(theme.onSurfaceVariant)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(theme.surfaceVariant)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                if !article.readingTime.isEmpty {
                    Text(article.readingTime)
                        .labelXSmall()
                        .foregroundColor(theme.outline)
                }
            }
        }
        .padding(20)
        .background(theme.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.outlineVariant.opacity(0.2), lineWidth: 1)
        )
    }
}
