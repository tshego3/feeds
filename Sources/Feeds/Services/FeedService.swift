// FeedService.swift — Network layer: fetches RSS XML from URLs with proxy fallback.
//
// C# parallel: an HttpClient service class, like you'd register in DI.
// Swift uses URLSession (≈ HttpClient) and async/await (same keywords as C#!).
// Swift errors use "throw" / "try" / "catch" — nearly identical to C# exceptions.

import Foundation
import os

private let logger = Logger(subsystem: "com.feeds.app", category: "FeedService")

// MARK: - Error Types

/// Custom error enum — C#: public enum FeedError or a set of custom Exception subclasses.
/// Swift "enum" can have associated values (like discriminated unions in F# / C# future).
/// Conforming to "Error" protocol = C# ": Exception" — makes it throwable.
enum FeedError: Error {
    case networkError(Error)         // C#: new NetworkException(innerException)
    case parsingError                // C#: new XmlParsingException()
    case feedUnavailable(status: Int) // C#: new HttpRequestException(statusCode)
}

// MARK: - Feed Service

/// Fetches and parses RSS feeds. C#: public class FeedService { }
/// "actor" or "class" could be used, but a simple enum with static methods works here.
/// In Swift, free functions and static methods are idiomatic — no need to wrap everything in a class.
enum FeedService {

    // "static func" = C# "public static async Task<List<FeedItem>>"
    // "async throws" = C# "async" + the method can throw (like Task that may fault).
    // "-> [FeedItem]" = return type. "[T]" = List<T>.
    static func fetchFeed(url: String) async throws -> [FeedItem] {
        // "guard let" = early return if nil — C#: if (x is not Type val) return;
        guard let feedURL = URL(string: url) else {
            throw FeedError.parsingError
        }

        // Direct fetch first — try the feed URL without a proxy
        var directRequest = URLRequest(url: feedURL)
        directRequest.timeoutInterval = 15
        if let (data, response) = try? await URLSession.shared.data(for: directRequest),
           let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 200 {
            return RSSXMLParser.parse(data: data)
        }

        // Direct fetch failed — safe to proceed to proxy fallback
        logger.debug("Direct fetch failed for \(url, privacy: .public), trying proxy services")

        // Proxy fallback — try proxies if direct fetch failed
        let proxyURLs = [
            "https://rss-proxy-api.netlify.app/.netlify/functions/fetch-xml?url=\(feedURL.absoluteString)",
            "https://api.codetabs.com/v1/proxy/?quest=\(feedURL.absoluteString)",
        ]

        // "for ... in" loop — same concept as C# foreach.
        for proxyString in proxyURLs {
            if let proxyURL = URL(string: proxyString) {
                var request = URLRequest(url: proxyURL)
                request.timeoutInterval = 15
                // Proxy errors are intentionally ignored — falls through to next proxy.
                if let (data, response) = try? await URLSession.shared.data(for: request),
                   let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    return RSSXMLParser.parse(data: data)
                } else {
                    logger.debug("Proxy \(proxyString, privacy: .public) failed, trying next")
                }
            }
        }

        // All attempts failed
        throw FeedError.feedUnavailable(status: 0)
    }
}
