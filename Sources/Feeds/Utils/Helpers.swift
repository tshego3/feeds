// Helpers.swift — Utility functions.
//
// C# parallel: a static helper class — public static class Helpers { }
// In Swift, putting functions in an enum with no cases prevents accidental instantiation
// (like a C# static class — can't be newed up).

import Foundation

/// Utility functions for the app.
/// C#: public static class Helpers { }
enum Helpers {

    /// Formats an RSS date string into a short display format.
    /// C#: public static string FormatDate(string dateString) { }
    ///
    /// RSS dates look like: "Mon, 12 May 2025 14:30:00 +0000"
    /// Output: "May 12, 2025"
    static func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")

        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }

        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .medium
        return outputFormatter.string(from: date)
    }

    /// Strips HTML tags and decodes common entities, returning plain text.
    static func stripHTML(_ html: String) -> String {
        guard html.contains("<") else { return html }
        return html
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Escapes special XML characters for safe embedding in XML/OPML output.
    static func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
