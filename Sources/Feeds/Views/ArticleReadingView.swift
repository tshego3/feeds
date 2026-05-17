import SwiftUI

/// Article reading view — full article reader with serif typography, AI summary, and related articles.
/// Matches article_reading_view/code.html design.
struct ArticleReadingView: View {
    @ObservedObject var viewModel: ArticleReadingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var htmlContentHeight: CGFloat = 300

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    metadataSection
                    headlineSection
                    heroImage
                    aiSummarySection
                    articleBody
                    Divider()
                        .background(Theme.outlineVariant)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                }
                .padding(.top, 80)
                .padding(.bottom, 80)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.background)

            // Floating action bar
            floatingBar
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let url = viewModel.shareURL {
                ShareSheet(activityItems: [url])
            }
        }
        .navigationBarBackButtonHidden(true)
        #if !os(macOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    // MARK: - Floating Bar

    private var floatingBar: some View {
        HStack(spacing: 20) {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left")
                        .labelSmall()
                    Text("Back to feed")
                        .labelSmall()
                }
                .foregroundColor(Theme.onSurfaceVariant)
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(Theme.outlineVariant)
                .frame(width: 1, height: 16)

            Button { viewModel.toggleBookmark() } label: {
                Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundColor(viewModel.isBookmarked ? Theme.primary : Theme.onSurfaceVariant)
            }
            .buttonStyle(.plain)

            Button { viewModel.showShareSheet = true } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(Theme.onSurfaceVariant)
            }
            .buttonStyle(.plain)

            Button { viewModel.cycleFontSize() } label: {
                Image(systemName: "textformat.size")
                    .foregroundColor(viewModel.fontSizeScale != 1.0 ? Theme.primary : Theme.onSurfaceVariant)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Theme.outlineVariant, lineWidth: 1)
        )
        .padding(.top, 16)
    }

    // MARK: - Metadata

    private var metadataSection: some View {
        HStack(spacing: 8) {
            Text(viewModel.feedTitle)
                .labelXSmall()
                .foregroundColor(Theme.onSurface)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Theme.surfaceContainerHigh)
                .clipShape(Capsule())

            Text("•")
                .foregroundColor(Theme.onSurfaceVariant)
                .labelXSmall()

            Text(Helpers.formatDate(viewModel.item.pubDate))
                .labelXSmall()
                .foregroundColor(Theme.onSurfaceVariant)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    // MARK: - Headline

    private var headlineSection: some View {
        Text(viewModel.item.title)
            .headlineLarge()
            .foregroundColor(Theme.primary)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
    }

    // MARK: - Hero Image

    private var heroImage: some View {
        Group {
            if let url = viewModel.item.displayImage {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .overlay(
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                EmptyView()
                            case .empty:
                                ProgressView()
                            @unknown default:
                                EmptyView()
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.outlineVariant, lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
    }

    // MARK: - AI Summary
    // TODO: Replace with on-device SLM summarisation (e.g. Apple Intelligence / local model)

    private var aiSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .labelXSmall()
                    .foregroundColor(Theme.primary)
                Text("AI SUMMARY")
                    .labelXSmall()
                    .foregroundColor(Theme.primary)
                    .textCase(.uppercase)
            }

            Text(viewModel.item.plainDescription)
                .bodyMedium()
                .foregroundColor(Theme.onSurface)
                .italic()
        }
        .padding(20)
        .background(Theme.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.outlineVariant, lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    // MARK: - Article Body

    private var isHTMLContent: Bool {
        viewModel.item.description.contains("<") && viewModel.item.description.contains(">")
    }

    private var articleBody: some View {
        VStack(alignment: .leading, spacing: 24) {
            if isHTMLContent {
                HTMLContentView(
                    html: viewModel.item.description,
                    fontScale: viewModel.fontSizeScale,
                    contentHeight: $htmlContentHeight
                )
                .frame(height: htmlContentHeight)
            } else {
                Text(viewModel.item.description)
                    .serifBody(scale: viewModel.fontSizeScale)
                    .foregroundColor(Theme.onSurface)
            }

            if let url = URL(string: viewModel.item.link) {
                Link(destination: url) {
                    Text("Read full article →")
                        .bodyLarge()
                        .foregroundColor(Theme.primary)
                        .underline()
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

}
