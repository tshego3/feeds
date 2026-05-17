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
        // DateFormatter ≈ C# DateTime.ParseExact / DateTimeFormatInfo.
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"  // RSS standard format
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")  // C#: CultureInfo.InvariantCulture

        // "guard let date = ... else { return dateString }" — parse or return original string.
        // C#: if (!DateTime.TryParseExact(..., out var date)) return dateString;
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }

        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .medium  // "May 12, 2025" — C#: date.ToString("MMM d, yyyy")
        return outputFormatter.string(from: date)
    }
}
