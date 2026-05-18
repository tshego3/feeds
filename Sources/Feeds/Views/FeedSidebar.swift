// FeedSidebar.swift — Sidebar navigation with feed selection.
//
// C# parallel: a TreeView or NavigationView with grouped items in a sidebar pane.
// Uses SwiftUI List with DisclosureGroup for expandable sections (≈ C# TreeViewItem).

import SwiftUI

/// Sidebar content for selecting feeds with grouped sub-items.
/// C#: public partial class FeedSidebar : ContentView { public FeedViewModel ViewModel { get; set; } }
struct FeedSidebar: View {

    @ObservedObject var viewModel: FeedViewModel
    @State var expandedGroups: Set<String> = []

    var body: some View {
        // List with selection binding drives NavigationSplitView navigation on iPhone
        List(selection: $viewModel.selectedFeedId) {
            ForEach(viewModel.menuItems) { menuItem in
                switch menuItem {
                case .single(let feed):
                    feedRow(feed)
                case .group(let id, let title, let feeds):
                    // Section with isExpanded — header taps toggle expand/collapse, not navigation
                    Section(title, isExpanded: expandedBinding(for: id)) {
                        ForEach(feeds) { feed in
                            feedRow(feed)
                        }
                    }
                }
            }
        }
        .navigationTitle("Feeds")
        #if os(iOS)
        .listStyle(.sidebar)
        #else
        .listStyle(.sidebar)
        #endif
        .onChange(of: viewModel.selectedFeedId) {
            guard let id = viewModel.selectedFeedId,
                  let feed = viewModel.allFeeds.first(where: { $0.id == id }) else { return }
            Task { await viewModel.selectFeed(feed) }
        }
    }

    private func feedRow(_ feed: RssFeedModel) -> some View {
        Text(feed.title)
            .font(.body)
            .tag(feed.id)
    }

    private func expandedBinding(for id: String) -> Binding<Bool> {
        Binding(
            get: { expandedGroups.contains(id) },
            set: { isExpanded in
                if isExpanded {
                    expandedGroups.insert(id)
                } else {
                    expandedGroups.remove(id)
                }
            }
        )
    }
}
