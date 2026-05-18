import SwiftUI

/// Article reading view — full article reader with serif typography, AI summary, and related articles.
/// Matches article_reading_view/code.html design.
struct ArticleReadingView: View {
    @ObservedObject var viewModel: ArticleReadingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var htmlContentHeight: CGFloat = 300
    @Environment(\.themeColors) private var theme
    @EnvironmentObject private var settings: SettingsViewModel
    @EnvironmentObject private var modelManager: ModelManagerViewModel
    @State private var generatedSummary: String?

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    metadataSection
                    headlineSection
                    heroImage
                    if settings.showAISummaries {
                        aiSummarySection
                    }
                    articleBody
                    Divider()
                        .background(theme.outlineVariant)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                }
                .padding(.top, 80)
                .padding(.bottom, 80)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(theme.background)

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
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width > 100 && abs(value.translation.height) < 100 {
                        dismiss()
                    }
                }
        )
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
                .foregroundColor(theme.onSurfaceVariant)
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(theme.outlineVariant)
                .frame(width: 1, height: 16)

            Button { viewModel.toggleBookmark() } label: {
                Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundColor(viewModel.isBookmarked ? theme.primary : theme.onSurfaceVariant)
            }
            .buttonStyle(.plain)

            Button { viewModel.showShareSheet = true } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(theme.onSurfaceVariant)
            }
            .buttonStyle(.plain)

            Button { viewModel.cycleFontSize() } label: {
                Image(systemName: "textformat.size")
                    .foregroundColor(viewModel.fontSizeScale != 1.0 ? theme.primary : theme.onSurfaceVariant)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(theme.outlineVariant, lineWidth: 1)
        )
        .padding(.top, 16)
    }

    // MARK: - Metadata

    private var metadataSection: some View {
        HStack(spacing: 8) {
            Text(viewModel.feedTitle)
                .labelXSmall()
                .foregroundColor(theme.onSurface)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(theme.surfaceContainerHigh)
                .clipShape(Capsule())

            Text("•")
                .foregroundColor(theme.onSurfaceVariant)
                .labelXSmall()

            Text(Helpers.formatDate(viewModel.item.pubDate))
                .labelXSmall()
                .foregroundColor(theme.onSurfaceVariant)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    // MARK: - Headline

    private var headlineSection: some View {
        Text(viewModel.item.title)
            .headlineLarge()
            .foregroundColor(theme.primary)
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
                            .stroke(theme.outlineVariant, lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
    }

    // MARK: - AI Summary

    private var aiSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .labelXSmall()
                    .foregroundColor(theme.primary)
                Text("AI SUMMARY")
                    .labelXSmall()
                    .foregroundColor(theme.primary)
                    .textCase(.uppercase)
                Spacer()
                if let model = modelManager.activeModel {
                    Text(model.name)
                        .labelXSmall()
                        .foregroundColor(theme.outline)
                }
            }

            if modelManager.isGenerating {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Generating summary…")
                        .bodyMedium()
                        .foregroundColor(theme.onSurfaceVariant)
                }
            } else if let summary = generatedSummary {
                Text(summary)
                    .bodyMedium()
                    .foregroundColor(theme.onSurface)
                    .italic()
            } else if modelManager.isModelLoaded {
                Button {
                    Task {
                        generatedSummary = await modelManager.generateSummary(
                            for: viewModel.item.plainDescription
                        )
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 14))
                        Text("Generate Summary")
                            .labelSmall()
                    }
                    .foregroundColor(theme.primary)
                }
                .buttonStyle(.plain)
            } else {
                Text("Download a model in Settings → AI Summaries to enable.")
                    .bodyMedium()
                    .foregroundColor(theme.onSurfaceVariant)
                    .italic()
            }
        }
        .padding(20)
        .background(theme.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.outlineVariant, lineWidth: 1)
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
                    .foregroundColor(theme.onSurface)
            }

            if let url = URL(string: viewModel.item.link) {
                Link(destination: url) {
                    Text("Read full article →")
                        .bodyLarge()
                        .foregroundColor(theme.primary)
                        .underline()
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

}
