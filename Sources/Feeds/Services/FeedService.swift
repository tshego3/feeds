// FeedService.swift — Network layer: fetches RSS XML from URLs with proxy fallback.
//
// C# parallel: an HttpClient service class, like you'd register in DI.
// Swift uses URLSession (≈ HttpClient) and async/await (same keywords as C#!).
// Swift errors use "throw" / "try" / "catch" — nearly identical to C# exceptions.

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(os)
import os
private let logger = Logger(subsystem: "co.za.eoitech.feeds", category: "FeedService")
#endif

// MARK: - Error Types

/// Custom error enum — C#: public enum FeedError or a set of custom Exception subclasses.
/// Swift "enum" can have associated values (like discriminated unions in F# / C# future).
/// Conforming to "Error" protocol = C# ": Exception" — makes it throwable.
enum FeedError: Error {
    case networkError(Error)         // C#: new NetworkException(innerException)
    case parsingError                // C#: new XmlParsingException()
    case feedUnavailable(status: Int) // C#: new HttpRequestException(statusCode)
}

// MARK: - Feed Service Protocol

protocol FeedServiceProtocol: Sendable {
    func fetchFeed(url: String) async throws -> [FeedItem]
}

// MARK: - Feed Service

struct FeedService: FeedServiceProtocol {

    private static let proxyBaseURLs = [
        "https://rss-proxy-api.netlify.app/.netlify/functions/fetch-xml?url=",
        "https://api.codetabs.com/v1/proxy/?quest=",
    ]

    func fetchFeed(url: String) async throws -> [FeedItem] {
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
        #if canImport(os)
        logger.debug("Direct fetch failed for \(url, privacy: .public), trying proxy services")
        #endif

        // Proxy fallback — try proxies if direct fetch failed
        let proxyURLs = Self.proxyBaseURLs.map { $0 + feedURL.absoluteString }

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
                    #if canImport(os)
                    logger.debug("Proxy \(proxyString, privacy: .public) failed, trying next")
                    #endif
                }
            }
        }

        // All attempts failed
        throw FeedError.feedUnavailable(status: 0)
    }
}
