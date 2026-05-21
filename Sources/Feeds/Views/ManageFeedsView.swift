import SwiftUI

/// Feed management view — add, delete, and configure RSS feed subscriptions.
/// C#: Like a UserControl with a ListView + Add/Remove buttons for feed management.
struct ManageFeedsView: View {
    @ObservedObject var feedViewModel: FeedViewModel
    @Environment(\.themeColors) var theme
    @State var showAddSheet = false
    @State var feedToDelete: RssFeedModel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                headerSection
                feedListSection
            }
            .frame(maxWidth: 720)
            .padding(.bottom, 80)
        }
        .frame(maxWidth: .infinity)
        .background(theme.background)
        .sheet(isPresented: $showAddSheet) {
            AddFeedSheet(feedViewModel: feedViewModel)
        }
        .alert("Remove Feed", isPresented: .init(
            get: { feedToDelete != nil },
            set: { if !$0 { feedToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { feedToDelete = nil }
            Button("Remove", role: .destructive) {
                if let feed = feedToDelete {
                    feedViewModel.deleteFeed(feed)
                    feedToDelete = nil
                }
            }
        } message: {
            if let feed = feedToDelete {
                Text("Remove \"\(feed.title)\" from your subscriptions?")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Manage Feeds")
                    .headlineLarge()
                    .foregroundColor(theme.primary)
                Text("Add, remove, or configure your RSS subscriptions.")
                    .bodyMedium()
                    .foregroundColor(theme.onSurfaceVariant)
            }
            Spacer()
            Button { showAddSheet = true } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(theme.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }

    // MARK: - Feed List

    private var feedListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Standalone feeds
            let standaloneFeeds = feedViewModel.menuItems.compactMap { item -> RssFeedModel? in
                guard case .single(let feed) = item else { return nil }
                return feed
            }
            if !standaloneFeeds.isEmpty {
                feedGroup(title: "General", feeds: standaloneFeeds)
            }

            // Grouped feeds
            let groupedItems = feedViewModel.menuItems.compactMap { item -> (String, String, [RssFeedModel])? in
                guard case .group(let id, let title, let feeds) = item else { return nil }
                return (id, title, feeds)
            }
            ForEach(groupedItems, id: \.0) { _, title, feeds in
                feedGroup(title: title, feeds: feeds)
            }
        }
        .padding(.horizontal, 24)
    }

    private func feedGroup(title: String, feeds: [RssFeedModel]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .labelSmall()
                .foregroundColor(theme.primary.opacity(0.5))
                .tracking(2)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(feeds) { feed in
                    feedRow(feed)
                    if feed.id != feeds.last?.id {
                        Rectangle().fill(theme.outlineVariant).frame(height: 1)
                    }
                }
            }
            .glassPanel()
        }
    }

    private func feedRow(_ feed: RssFeedModel) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(feed.title)
                    .bodyMedium()
                    .foregroundColor(theme.onSurface)
                    .lineLimit(1)
                Text(feed.url)
                    .labelXSmall()
                    .foregroundColor(theme.onSurfaceVariant)
                    .lineLimit(1)
            }

            Spacer()

            // Hero image toggle
            // C#: like a CheckBox bound to SuppressHeroImage property
            Button {
                feedViewModel.toggleSuppressHeroImage(feed)
            } label: {
                Image(systemName: feed.suppressHeroImage ? "photo.fill.on.rectangle.fill" : "photo.on.rectangle")
                    .font(.system(size: 16))
                    .foregroundColor(feed.suppressHeroImage ? theme.primary : theme.onSurfaceVariant)
            }
            .buttonStyle(.plain)
            .help("Toggle hero image suppression")

            // Delete button
            Button {
                feedToDelete = feed
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(theme.error)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }
}

// MARK: - Add Feed Sheet

/// Sheet for adding a new RSS feed subscription.
/// C#: Like a modal dialog with TextBox inputs for URL and title.
struct AddFeedSheet: View {
    @ObservedObject var feedViewModel: FeedViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColors) var theme
    @State var title = ""
    @State var url = ""
    @State var groupTitle = ""
    @State var suppressHeroImage = false
    @State var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title field
                    fieldSection(label: "Feed Name") {
                        TextField("e.g. TechCrunch", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }

                    // URL field
                    fieldSection(label: "Feed URL") {
                        TextField("https://example.com/feed/", text: $url)
                            .textFieldStyle(.roundedBorder)
                            #if !os(macOS)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            #endif
                    }

                    // Group field (optional)
                    fieldSection(label: "Group (Optional)") {
                        TextField("e.g. Tech, News, Sports", text: $groupTitle)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Hero image suppression toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Suppress Hero Image")
                                .bodyMedium()
                                .foregroundColor(theme.onSurface)
                            Text("Enable if feed already embeds images in article content")
                                .labelXSmall()
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                        Spacer()
                        Toggle("", isOn: $suppressHeroImage)
                            .labelsHidden()
                            .tint(theme.primary)
                    }
                    .padding(16)
                    .glassPanel()

                    if let error = errorMessage {
                        Text(error)
                            .bodyMedium()
                            .foregroundColor(theme.error)
                    }
                }
                .padding(24)
            }
            .background(theme.background)
            .navigationTitle("Add Feed")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addFeed() }
                        .disabled(title.isEmpty || url.isEmpty)
                }
            }
        }
    }

    private func fieldSection<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .labelXSmall()
                .foregroundColor(theme.onSurfaceVariant)
                .tracking(1)
            content()
        }
    }

    private func addFeed() {
        // Validate URL — C#: Uri.TryCreate(url, UriKind.Absolute, out _)
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsedURL = URL(string: trimmedURL),
              parsedURL.scheme == "https" || parsedURL.scheme == "http",
              let host = parsedURL.host, !host.isEmpty else {
            errorMessage = "Please enter a valid URL starting with https:// or http://"
            return
        }

        let group = groupTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        feedViewModel.addFeed(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            url: trimmedURL,
            groupTitle: group.isEmpty ? nil : group,
            suppressHeroImage: suppressHeroImage
        )
        dismiss()
    }
}
