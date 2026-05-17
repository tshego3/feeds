// ContentView.swift — The main screen layout with sidebar navigation.
//
// C# parallel: like MainPage.xaml.cs in MAUI, or MainWindow.xaml in WPF.
// SwiftUI is declarative (like XAML) but written in Swift code, not markup.
// Uses NavigationSplitView for sidebar + detail pane (≈ C# SplitView / NavigationView with Master-Detail).
import SwiftUI

/// Root view — desktop uses sidebar NavigationDrawer, mobile uses bottom tab bar.
/// Implements the "Monolithic Clarity" design system layout.
struct ContentView: View {

    // "@StateObject" creates and owns a ViewModel instance.
    // C# MAUI: like "BindingContext = new FeedViewModel();" in the constructor.
    // "@StateObject" keeps the object alive across view re-renders (like a singleton per view).
    @StateObject var viewModel = FeedViewModel()
    @EnvironmentObject var bookmarkViewModel: BookmarkViewModel
    @EnvironmentObject private var settings: SettingsViewModel
    @State private var selectedTab: AppTab = .home
    @State private var selectedArticle: FeedItem?
    @State private var showMobileDrawer: Bool = false
    @State private var homePath = NavigationPath()
    @State private var unreadPath = NavigationPath()
    @Environment(\.themeColors) private var theme

    var body: some View {
        // NavigationSplitView ≈ C# SplitView / Master-Detail — sidebar + detail pane.
        Group {
            #if os(macOS)
            desktopLayout
            #else
            adaptiveLayout
            #endif
        }
        // ".task { }" runs async work when the view appears — C#: OnAppearing += async () => { }
        // This replaces ".onAppear" when you need async/await.
        .task {
            viewModel.loadConfig()
            guard let first = viewModel.allFeeds.first else { return }
            viewModel.selectedFeedId = first.id
        }
        .onChange(of: settings.autoRefresh) { _, enabled in
            if enabled {
                viewModel.startAutoRefresh()
            } else {
                viewModel.stopAutoRefresh()
            }
        }
        .onAppear {
            guard settings.autoRefresh else { return }
            viewModel.startAutoRefresh()
        }
    }

    // MARK: - Desktop Layout (macOS always uses sidebar)

    private var desktopLayout: some View {
        HStack(spacing: 0) {
            NavigationDrawer(selectedTab: $selectedTab, viewModel: viewModel)
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(theme.background)
    }

    // MARK: - Adaptive Layout (iOS: sidebar on iPad, tabs on iPhone)

    private var adaptiveLayout: some View {
        GeometryReader { geo in
            let isWide = geo.size.width > 700
            if isWide {
                HStack(spacing: 0) {
                    NavigationDrawer(selectedTab: $selectedTab, viewModel: viewModel)
                    tabContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .background(theme.background)
            } else {
                ZStack(alignment: .bottom) {
                    VStack(spacing: 0) {
                        mobileTopBar
                        tabContent
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    MobileTabBar(selectedTab: $selectedTab)
                }
                .overlay(alignment: .leading) {
                    if showMobileDrawer {
                        mobileDrawerOverlay
                    }
                }
                .background(theme.background)
            }
        }
    }

    // MARK: - Mobile Top Bar

    private var mobileTopBar: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showMobileDrawer.toggle()
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20))
                    .foregroundColor(theme.primary)
            }
            .buttonStyle(.plain)

            Text("feeds")
                .font(.system(size: 24, weight: .bold))
                .tracking(-1)
                .foregroundColor(theme.primary)
            Spacer()
            Button {
                selectedTab = .search
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundColor(theme.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(theme.surface.opacity(0.8))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.outlineVariant)
                .frame(height: 1)
        }
    }

    // MARK: - Mobile Drawer Overlay

    private var mobileDrawerOverlay: some View {
        ZStack(alignment: .leading) {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showMobileDrawer = false
                    }
                }

            NavigationDrawer(selectedTab: $selectedTab, viewModel: viewModel)
                .transition(.move(edge: .leading))
                .onChange(of: selectedTab) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showMobileDrawer = false
                    }
                }
                .onChange(of: viewModel.selectedFeedId) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showMobileDrawer = false
                    }
                }
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:
            NavigationStack(path: $homePath) {
                DashboardView(viewModel: viewModel)
                    .onChange(of: viewModel.selectedFeedId) {
                        homePath = NavigationPath()
                        guard let id = viewModel.selectedFeedId,
                              let feed = viewModel.allFeeds.first(where: { $0.id == id }) else { return }
                        Task { await viewModel.selectFeed(feed) }
                    }
                    .navigationDestination(for: FeedItem.self) { item in
                        ArticleReadingView(
                            viewModel: ArticleReadingViewModel(
                                item: item,
                                bookmarkViewModel: bookmarkViewModel,
                                feedTitle: viewModel.selectedFeed?.title ?? "Source"
                            )
                        )
                        .onAppear { viewModel.markAsRead(item) }
                    }
            }
        case .unread:
            NavigationStack(path: $unreadPath) {
                DashboardView(viewModel: viewModel, filterUnreadOnly: true)
                    .onChange(of: viewModel.selectedFeedId) {
                        unreadPath = NavigationPath()
                        guard let id = viewModel.selectedFeedId,
                              let feed = viewModel.allFeeds.first(where: { $0.id == id }) else { return }
                        Task { await viewModel.selectFeed(feed) }
                    }
                    .navigationDestination(for: FeedItem.self) { item in
                        ArticleReadingView(
                            viewModel: ArticleReadingViewModel(
                                item: item,
                                bookmarkViewModel: bookmarkViewModel,
                                feedTitle: viewModel.selectedFeed?.title ?? "Source"
                            )
                        )
                        .onAppear { viewModel.markAsRead(item) }
                    }
            }
        case .bookmarks:
            NavigationStack {
                SavedArticlesView()
                    .navigationDestination(for: FeedItem.self) { item in
                        ArticleReadingView(
                            viewModel: ArticleReadingViewModel(
                                item: item,
                                bookmarkViewModel: bookmarkViewModel
                            )
                        )
                        .onAppear { viewModel.markAsRead(item) }
                    }
            }
        case .discover:
            NavigationStack {
                ExploreView(viewModel: viewModel)
            }
        case .search:
            NavigationStack {
                SearchView(viewModel: viewModel)
                    .navigationDestination(for: FeedItem.self) { item in
                        ArticleReadingView(
                            viewModel: ArticleReadingViewModel(
                                item: item,
                                bookmarkViewModel: bookmarkViewModel,
                                feedTitle: viewModel.selectedFeed?.title ?? "Source"
                            )
                        )
                        .onAppear { viewModel.markAsRead(item) }
                    }
            }
        case .settings:
            NavigationStack {
                SettingsView(feedViewModel: viewModel)
            }
        }
    }
}
