import SwiftUI

/// In-app banner shown when auto-refresh detects new articles.
/// Cross-platform — works on iOS, macOS, and Android.
struct NewArticlesBanner: View {

    let message: String
    let onDismiss: () -> Void

    @Environment(\.themeColors) var theme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "newspaper.fill")
                .foregroundColor(theme.onPrimary)
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.onPrimary)
            Spacer()
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(theme.onPrimary.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(theme.primary.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .task {
            try? await Task.sleep(for: .seconds(5))
            onDismiss()
        }
    }
}
