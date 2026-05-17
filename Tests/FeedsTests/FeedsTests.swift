import Testing
@testable import Feeds
import Foundation

// MARK: - Helpers Tests

@Suite("Helpers Tests")
struct HelpersTests {
    @Test("formatDate parses valid RSS date")
    func formatDateValid() {
        let result = Helpers.formatDate("Mon, 12 May 2025 14:30:00 +0000")
        // Output format depends on system locale; verify it parsed (not returned raw)
        #expect(result != "Mon, 12 May 2025 14:30:00 +0000")
        #expect(result.contains("2025"))
    }

    @Test("formatDate returns original string for invalid input")
    func formatDateInvalid() {
        let result = Helpers.formatDate("not-a-date")
        #expect(result == "not-a-date")
    }
}

// MARK: - FeedItem Tests

@Suite("FeedItem Tests")
struct FeedItemTests {
    @Test("displayImage returns first valid URL")
    func displayImageValid() {
        let item = FeedItem(
            title: "Test",
            link: "https://example.com",
            description: "Desc",
            pubDate: "",
            imageURLs: [nil, "https://example.com/image.jpg", "https://example.com/other.jpg"]
        )
        #expect(item.displayImage == URL(string: "https://example.com/image.jpg"))
    }

    @Test("displayImage returns nil when no valid URLs")
    func displayImageNil() {
        let item = FeedItem(
            title: "Test",
            link: "https://example.com",
            description: "Desc",
            pubDate: "",
            imageURLs: [nil, nil]
        )
        #expect(item.displayImage == nil)
    }

    @Test("displayImage returns nil for empty array")
    func displayImageEmpty() {
        let item = FeedItem(
            title: "Test",
            link: "https://example.com",
            description: "Desc",
            pubDate: "",
            imageURLs: []
        )
        #expect(item.displayImage == nil)
    }

    @Test("displayImage skips empty URL strings")
    func displayImageSkipsEmpty() {
        let item = FeedItem(
            title: "Test",
            link: "https://example.com",
            description: "Desc",
            pubDate: "",
            imageURLs: ["", "https://example.com/valid.jpg"]
        )
        #expect(item.displayImage == URL(string: "https://example.com/valid.jpg"))
    }
}

// MARK: - RSSXMLParser Tests

@Suite("RSSXMLParser Tests")
struct RSSXMLParserTests {
    @Test("parse extracts items from valid RSS XML")
    func parseValidXML() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
        <channel>
            <title>Test Feed</title>
            <item>
                <title>Article One</title>
                <link>https://example.com/1</link>
                <description>First article</description>
                <pubDate>Mon, 12 May 2025 14:30:00 +0000</pubDate>
            </item>
            <item>
                <title>Article Two</title>
                <link>https://example.com/2</link>
                <description>Second article</description>
                <pubDate>Tue, 13 May 2025 10:00:00 +0000</pubDate>
            </item>
        </channel>
        </rss>
        """
        let data = Data(xml.utf8)
        let items = RSSXMLParser.parse(data: data)

        #expect(items.count == 2)
        #expect(items[0].title == "Article One")
        #expect(items[0].link == "https://example.com/1")
        #expect(items[0].description == "First article")
        #expect(items[1].title == "Article Two")
    }

    @Test("parse returns empty array for non-XML data")
    func parseInvalidXML() {
        let data = Data("not xml at all".utf8)
        let items = RSSXMLParser.parse(data: data)
        #expect(items.isEmpty)
    }

    @Test("parse extracts media:content image URLs")
    func parseMediaContent() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/">
        <channel>
            <item>
                <title>With Image</title>
                <link>https://example.com/1</link>
                <description>Has media</description>
                <pubDate>Mon, 12 May 2025 14:30:00 +0000</pubDate>
                <media:content url="https://example.com/image.jpg" />
            </item>
        </channel>
        </rss>
        """
        let data = Data(xml.utf8)
        let items = RSSXMLParser.parse(data: data)

        #expect(items.count == 1)
        #expect(items[0].imageURLs.contains("https://example.com/image.jpg"))
    }

    @Test("parse extracts enclosure image URLs")
    func parseEnclosure() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
        <channel>
            <item>
                <title>With Enclosure</title>
                <link>https://example.com/1</link>
                <description>Has enclosure</description>
                <pubDate>Mon, 12 May 2025 14:30:00 +0000</pubDate>
                <enclosure url="https://example.com/photo.jpg" type="image/jpeg" />
            </item>
        </channel>
        </rss>
        """
        let data = Data(xml.utf8)
        let items = RSSXMLParser.parse(data: data)

        #expect(items.count == 1)
        #expect(items[0].imageURLs.contains("https://example.com/photo.jpg"))
    }

    @Test("parse trims whitespace from fields")
    func parseTrimming() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
        <channel>
            <item>
                <title>  Padded Title  </title>
                <link>https://example.com</link>
                <description>desc</description>
                <pubDate></pubDate>
            </item>
        </channel>
        </rss>
        """
        let data = Data(xml.utf8)
        let items = RSSXMLParser.parse(data: data)

        #expect(items.count == 1)
        #expect(items[0].title == "Padded Title")
    }
}

// MARK: - FeedViewModel Tests

@Suite("FeedViewModel Tests")
struct FeedViewModelTests {
    @Test("initial state is correct")
    @MainActor
    func initialState() {
        let vm = FeedViewModel()
        #expect(vm.feedItems.isEmpty)
        #expect(vm.allFeeds.isEmpty)
        #expect(vm.selectedFeed == nil)
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoading == false)
        #expect(vm.hasItems == false)
    }
}
