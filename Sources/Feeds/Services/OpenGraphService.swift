import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Fetches Open Graph preview images from article URLs.
/// C#: Similar to a static HttpClient utility class with GetStringAsync
struct OpenGraphService: Sendable {

    /// Extracts the og:image URL from a webpage's HTML meta tags.
    /// C#: async Task<Uri?> FetchOGImageAsync(string articleUrl)
    func fetchOGImage(for articleURL: String) async -> URL? {
        guard let url = URL(string: articleURL) else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        // Only fetch the head portion — many servers send HTML progressively
        request.setValue("text/html", forHTTPHeaderField: "Accept")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let html = String(data: data.prefix(50_000), encoding: .utf8) else {
            return nil
        }

        return extractOGImage(from: html)
    }

    /// Parses og:image content from HTML meta tags.
    /// C#: like Regex.Match(html, pattern).Groups[1].Value
    private func extractOGImage(from html: String) -> URL? {
        // Match <meta property="og:image" content="...">
        // Handles both single and double quotes, and varying attribute order
        let patterns = [
            #"<meta[^>]+property\s*=\s*["']og:image["'][^>]+content\s*=\s*["']([^"']+)["']"#,
            #"<meta[^>]+content\s*=\s*["']([^"']+)["'][^>]+property\s*=\s*["']og:image["']"#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            if let match = regex.firstMatch(in: html, range: range),
               let urlRange = Range(match.range(at: 1), in: html) {
                // C#: like WebUtility.HtmlDecode(match.Groups[1].Value)
                let rawString = String(html[urlRange])
                let decoded = decodeHTMLEntities(rawString)
                if let url = URL(string: decoded), decoded.contains("http") {
                    return url
                }
            }
        }

        return nil
    }

    /// Decodes common HTML entities in og:image URLs (e.g. &#x3A; → :, &amp; → &).
    /// C#: equivalent to System.Net.WebUtility.HtmlDecode(input)
    private func decodeHTMLEntities(_ string: String) -> String {
        var result = string
        // Decode hex entities: &#x3A; → :
        let hexPattern = #"&#x([0-9a-fA-F]+);"#
        if let regex = try? NSRegularExpression(pattern: hexPattern) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            let matches = regex.matches(in: result, range: range).reversed()
            for match in matches {
                guard let fullRange = Range(match.range, in: result),
                      let hexRange = Range(match.range(at: 1), in: result) else { continue }
                let hex = String(result[hexRange])
                if let code = UInt32(hex, radix: 16), let scalar = Unicode.Scalar(code) {
                    result.replaceSubrange(fullRange, with: String(scalar))
                }
            }
        }
        // Decode decimal entities: &#58; → :
        let decPattern = #"&#([0-9]+);"#
        if let regex = try? NSRegularExpression(pattern: decPattern) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            let matches = regex.matches(in: result, range: range).reversed()
            for match in matches {
                guard let fullRange = Range(match.range, in: result),
                      let numRange = Range(match.range(at: 1), in: result) else { continue }
                let num = String(result[numRange])
                if let code = UInt32(num), let scalar = Unicode.Scalar(code) {
                    result.replaceSubrange(fullRange, with: String(scalar))
                }
            }
        }
        // Decode named entities
        result = result.replacingOccurrences(of: "&amp;", with: "&")
        result = result.replacingOccurrences(of: "&lt;", with: "<")
        result = result.replacingOccurrences(of: "&gt;", with: ">")
        result = result.replacingOccurrences(of: "&quot;", with: "\"")
        result = result.replacingOccurrences(of: "&apos;", with: "'")
        return result
    }
}
