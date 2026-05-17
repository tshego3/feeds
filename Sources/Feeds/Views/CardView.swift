// CardView.swift — A single feed article card.
//
// C# parallel: a UserControl or DataTemplate for one RSS item.
// In WPF/MAUI terms: a custom control with Image, Labels, and a Link button.

import SwiftUI

/// Displays one FeedItem as a card with image, title, description, and link.
/// C#: public partial class CardView : ContentView { public FeedItem Item { get; set; } }
struct CardView: View {

    // "let" property = immutable, set once at init. C#: public required FeedItem Item { get; init; }
    // No "@State" because this view doesn't own/mutate this data — it just displays it.
    let item: FeedItem

    var body: some View {
        // VStack = vertical StackLayout. C#: new StackLayout { Orientation = Vertical }
        // "alignment: .leading" = left-align children. C#: HorizontalOptions = Start
        VStack(alignment: .leading, spacing: 8) {

            // AsyncImage loads an image from a URL asynchronously.
            // C#: like an Image control with an HttpClient-backed ImageSource.
            // "if let url" safely unwraps the optional — C#: if (item.DisplayImage is Uri url) { }
            if let url = item.displayImage {
                AsyncImage(url: url) { phase in
                    // "switch" on the loading phase — C#: pattern matching
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()                    // Makes image scalable
                            .aspectRatio(contentMode: .fill) // C#: Aspect = AspectFill
                            .frame(height: 200)             // Fixed height — C#: HeightRequest = 200
                            .clipped()                      // Clips overflow — C#: IsClippedToBounds = true
                    case .failure:
                        // Fallback icon on error — C#: FallbackSource
                        Image(systemName: "photo")
                            .frame(height: 200)
                    case .empty:
                        // Loading state — C#: ActivityIndicator
                        ProgressView()
                            .frame(height: 200)
                    @unknown default:
                        // "@unknown default" catches future enum cases — defensive programming.
                        EmptyView()
                    }
                }
            }

            // Text views — C#: new Label { Text = "...", FontSize = ... }
            Text(item.title)
                .font(.headline)        // C#: FontAttributes = Bold, FontSize = 18
                .lineLimit(2)           // C#: MaxLines = 2

            Text(item.description)
                .font(.body)            // C#: FontSize = 14
                .lineLimit(3)
                .foregroundColor(.secondary) // C#: TextColor = Colors.Gray

            // HStack = horizontal StackLayout. Children laid out left to right.
            HStack {
                // Link opens a URL in the browser — C#: Launcher.OpenAsync(url)
                // "URL(string:)!" force-unwraps — C#: new Uri(string) (crashes if nil — avoid in production).
                if let url = URL(string: item.link) {
                    Link("View", destination: url)
                        .font(.caption)
                }

                // Spacer() pushes remaining items to the right — C#: like a Grid column with Star width.
                Spacer()

                Text(Helpers.formatDate(item.pubDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()                      // Inner padding — C#: Padding = new Thickness(16)
        #if os(macOS)
        .background(Color(NSColor.windowBackgroundColor))
        #else
        .background(Color(UIColor.systemBackground))
        #endif
        .cornerRadius(8)               // C#: CornerRadius = 8 (on a Frame/Border)
        .shadow(radius: 2)             // C#: like a BoxShadow or elevation effect
    }
}
