import Foundation

/// Represents a discoverable feed source for the Explore page.
struct DiscoverFeed: Identifiable, Equatable {
    let id: String
    let name: String
    let category: String
    let description: String
    let initials: String

    init(id: String = UUID().uuidString, name: String, category: String, description: String = "", initials: String = "") {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.initials = initials.isEmpty ? String(name.prefix(2)).uppercased() : initials
    }
}
