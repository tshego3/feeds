// RSSXMLParser.swift — Parses RSS XML into FeedItem models.
//
// C# parallel: like using XmlReader or XDocument to parse RSS XML.
// Swift's Foundation.XMLParser is SAX-style (event-driven), similar to C# XmlReader.
// It uses a delegate pattern (≈ C# event handlers or callback interface).

import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

// MARK: - XML Parser

/// Parses raw XML data into an array of FeedItem.
/// C#: public static class RSSXMLParser { public static List<FeedItem> Parse(byte[] data) { } }
///
/// "NSObject" — base class required for Objective-C interop (XMLParser delegate is ObjC-based).
/// C#: like inheriting from a COM interop base class.
/// "XMLParserDelegate" — the callback protocol. C#: implementing IXmlParserHandler interface.
class RSSXMLParser: NSObject, XMLParserDelegate {

    // "private(set)" = C#: public List<FeedItem> Items { get; private set; }
    // "var" = mutable variable (vs "let" = immutable/readonly).
    private(set) var items: [FeedItem] = []

    // Private state for tracking XML parsing position
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentDescription = ""
    private var currentPubDate = ""
    private var currentImageURLs: [String?] = []
    private var insideItem = false

    // MARK: - Public API

    /// Static convenience method — creates parser, runs it, returns results.
    /// C#: public static List<FeedItem> Parse(byte[] data) { ... }
    static func parse(data: Data) -> [FeedItem] {
        let handler = RSSXMLParser()
        let parser = XMLParser(data: data)  // C#: new XmlReader(stream)
        parser.delegate = handler           // C#: parser.OnElement += handler.HandleElement
        parser.parse()                      // C#: while (reader.Read()) { ... } — runs synchronously
        return handler.items
    }

    // MARK: - XMLParserDelegate Methods
    // These are callback methods invoked by the parser — like C# event handlers.
    // "didStartElement" fires when "<tag>" is encountered.
    // "foundCharacters" fires for text content between tags.
    // "didEndElement" fires when "</tag>" is encountered.

    /// Called when an opening XML tag is found. C#: void OnStartElement(string name, Dictionary<string,string> attrs)
    /// The underscore "_" means the parameter has no external label — C#: unnamed parameter.
    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName

        if elementName == "item" {
            // Reset accumulators for new item
            insideItem = true
            currentTitle = ""
            currentLink = ""
            currentDescription = ""
            currentPubDate = ""
            currentImageURLs = []
        }

        // Extract image URLs from media/enclosure attributes
        // "if let" unwraps optionals — C#: if (dict.TryGetValue("url", out var url)) { }
        if elementName == "media:content" || elementName == "media:thumbnail" || elementName == "enclosure" {
            if let url = attributeDict["url"] {
                currentImageURLs.append(url)
            }
        }
    }

    /// Called with text content between tags. C#: void OnText(string text)
    /// "+=" appends — same as C# string concatenation (parser may call this multiple times per element).
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        // "guard" = early return. C#: if (!insideItem) return;
        guard insideItem else { return }

        // "switch" in Swift doesn't fall through by default (no "break" needed — opposite of C#).
        switch currentElement {
        case "title": currentTitle += string
        case "link": currentLink += string
        case "description": currentDescription += string
        case "pubDate": currentPubDate += string
        default: break  // "default" is required if not exhaustive — like C# "default:" case
        }
    }

    /// Called when a closing XML tag is found. C#: void OnEndElement(string name)
    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            // ".trimmingCharacters(in:)" = C# ".Trim()"
            // ".whitespaceAndNewlines" = C# char.IsWhiteSpace equivalent
            let item = FeedItem(
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                description: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                pubDate: currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines),
                imageURLs: currentImageURLs
            )
            items.append(item)  // C#: items.Add(item)
            insideItem = false
        }
    }
}
