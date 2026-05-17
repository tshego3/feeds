import Foundation

/// ViewModel for the article reading view — manages bookmark state and article metadata.
@MainActor
class ArticleReadingViewModel: ObservableObject {

    @Published private(set) var isBookmarked: Bool = false
    @Published var fontSizeScale: Double = 1.0
    @Published var showShareSheet: Bool = false

    private let bookmarkViewModel: BookmarkViewModel
    let item: FeedItem

    init(item: FeedItem, bookmarkViewModel: BookmarkViewModel) {
        self.item = item
        self.bookmarkViewModel = bookmarkViewModel
        self.isBookmarked = bookmarkViewModel.isBookmarked(item)
    }

    func toggleBookmark() {
        bookmarkViewModel.toggle(item)
        isBookmarked = bookmarkViewModel.isBookmarked(item)
    }

    func cycleFontSize() {
        // Cycle through 3 sizes: 1.0 → 1.2 → 1.4 → 1.0
        switch fontSizeScale {
        case ..<1.1: fontSizeScale = 1.2
        case ..<1.3: fontSizeScale = 1.4
        default: fontSizeScale = 1.0
        }
    }

    var shareURL: URL? {
        URL(string: item.link)
    }
}
