// ContentView.swift — The main screen layout with sidebar navigation.
//
// C# parallel: like MainPage.xaml.cs in MAUI, or MainWindow.xaml in WPF.
// SwiftUI is declarative (like XAML) but written in Swift code, not markup.
// Uses NavigationSplitView for sidebar + detail pane (≈ C# SplitView / NavigationView with Master-Detail).

import SwiftUI

/// The root view of the app. C#: public partial class MainPage : ContentPage { }
/// "View" protocol ≈ C# IView interface — anything that can draw UI.
struct ContentView: View {

    // "@StateObject" creates and owns a ViewModel instance.
    // C# MAUI: like "BindingContext = new FeedViewModel();" in the constructor.
    // "@StateObject" keeps the object alive across view re-renders (like a singleton per view).
    @StateObject var viewModel = FeedViewModel()

    var body: some View {
        // NavigationSplitView ≈ C# SplitView / Master-Detail — sidebar + detail pane.
        NavigationSplitView {
            // Sidebar pane — feed list with grouped sub-items
            FeedSidebar(viewModel: viewModel)
        } detail: {
            // Detail pane — article grid
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if viewModel.hasItems {
                    feedGridView
                } else {
                    emptyStateView
                }
            }
            .navigationTitle(viewModel.selectedFeed?.title ?? "Feeds")
        }
        // ".task { }" runs async work when the view appears — C#: OnAppearing += async () => { }
        // This replaces ".onAppear" when you need async/await.
        .task {
            viewModel.loadConfig()
            guard let first = viewModel.allFeeds.first else { return }
            viewModel.selectedFeedId = first.id
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 100)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task {
                    if let feed = viewModel.selectedFeed {
                        await viewModel.selectFeed(feed)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    private var feedGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 16) {
                ForEach(viewModel.feedItems) { item in
                    CardView(item: item)
                }
            }
            .padding()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No articles found.")
                .font(.body)
                .foregroundColor(.secondary)
            Text("Select a feed from the sidebar to get started.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}
