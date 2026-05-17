import Foundation

/// Represents a bookmarked/saved article.
struct SavedArticle: Identifiable, Equatable {
    let id: UUID
    let title: String
    let source: String
    let description: String
    let link: String
    let savedDate: Date
    let tag: String
    let readingTime: String
    let imageURL: URL?

    init(
        id: UUID = UUID(),
        title: String,
        source: String,
        description: String = "",
        link: String = "",
        savedDate: Date = Date(),
        tag: String = "readlater",
        readingTime: String = "",
        imageURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.source = source
        self.description = description
        self.link = link
        self.savedDate = savedDate
        self.tag = tag
        self.readingTime = readingTime
        self.imageURL = imageURL
    }
}
