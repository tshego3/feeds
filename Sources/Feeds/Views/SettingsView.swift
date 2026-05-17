import SwiftUI

/// Settings view — account, appearance, preferences, data management.
/// Matches settings/code.html design with glassmorphic cards.
struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsViewModel
    @ObservedObject var feedViewModel: FeedViewModel
    @State private var showExportSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                headerSection
                appearanceSection
                preferencesSection
                dataManagementSection
                footerSection
            }
            .frame(maxWidth: 720)
            .padding(.bottom, 80)
        }
        .frame(maxWidth: .infinity)
        .background(Theme.background)
        .sheet(isPresented: $showExportSheet) {
            let opml = generateOPML()
            ShareSheet(activityItems: [opml])
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .headlineLarge()
                .foregroundColor(Theme.primary)
            Text("Configure your reading experience and account preferences.")
                .bodyMedium()
                .foregroundColor(Theme.onSurfaceVariant)
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }

    // MARK: - Account

    private var accountSection: some View {
        settingsSection(title: "Account") {
            HStack(spacing: 16) {
                Circle()
                    .fill(Theme.surfaceContainerHighest)
                    .frame(width: 48, height: 48)
                    .overlay(
                    Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.primary)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Guest")
                        .headlineMedium()
                        .foregroundColor(Theme.primary)
                    Text("Local only — no account")
                        .labelSmall()
                        .foregroundColor(Theme.onSurfaceVariant)
                }

                Spacer()

                Button("Manage") { }
                    .labelSmall()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.primary)
                    .foregroundColor(Theme.onPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .buttonStyle(.plain)
            }
            .padding(20)
            .glassPanel()
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        settingsSection(title: "Appearance") {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    autoThemeOption
                    themeOption("Light", colors: ThemeColors.light)
                    themeOption("Dark", colors: ThemeColors.dark)
                    themeOption("Monochrome", colors: ThemeColors.monochrome)
                }

                Button {
                    settings.cycleAppearance()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: appearanceCycleIcon)
                            .font(.system(size: 14))
                        Text(settings.selectedTheme)
                            .labelSmall()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.surfaceContainerHigh)
                    .foregroundColor(Theme.onSurface)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .glassPanel()
        }
    }

    private var appearanceCycleIcon: String {
        switch settings.selectedTheme {
        case "Auto": return "circle.lefthalf.filled"
        case "Light": return "sun.max.fill"
        case "Dark": return "moon.fill"
        default: return "circle.fill"
        }
    }

    private var autoThemeOption: some View {
        Button {
            settings.selectedTheme = "Auto"
        } label: {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [ThemeColors.light.background, ThemeColors.dark.background],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [ThemeColors.light.primary, ThemeColors.dark.primary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 30, height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [ThemeColors.light.onSurfaceVariant, ThemeColors.dark.onSurfaceVariant],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 22, height: 3)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                settings.selectedTheme == "Auto" ? Theme.primary : Color.clear,
                                lineWidth: 2
                            )
                    )
                Text("Auto")
                    .labelXSmall()
                    .foregroundColor(settings.selectedTheme == "Auto" ? Theme.primary : Theme.onSurfaceVariant)
            }
        }
        .buttonStyle(.plain)
    }

    private func themeOption(_ name: String, colors: ThemeColors) -> some View {
        Button {
            settings.selectedTheme = name
        } label: {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(colors.background)
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(colors.primary)
                                .frame(width: 30, height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(colors.onSurfaceVariant)
                                .frame(width: 22, height: 3)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                settings.selectedTheme == name ? Theme.primary : Color.clear,
                                lineWidth: 2
                            )
                    )
                Text(name)
                    .labelXSmall()
                    .foregroundColor(settings.selectedTheme == name ? Theme.primary : Theme.onSurfaceVariant)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        settingsSection(title: "Preferences") {
            VStack(spacing: 0) {
                preferenceToggle(
                    title: "Auto-Refresh Feeds",
                    subtitle: "Synchronize content every 15 minutes",
                    isOn: $settings.autoRefresh
                )

                Rectangle().fill(Theme.outlineVariant).frame(height: 1)

                preferenceToggle(
                    title: "Mark as Read on Scroll",
                    subtitle: "Automatically clear items as they leave the viewport",
                    isOn: $settings.markReadOnScroll
                )
            }
            .glassPanel()
        }
    }

    private func preferenceToggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .bodyMedium()
                    .foregroundColor(Theme.onSurface)
                Text(subtitle)
                    .labelXSmall()
                    .foregroundColor(Theme.onSurfaceVariant)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Theme.primary)
        }
        .padding(16)
    }

    // MARK: - Data Management

    private var dataManagementSection: some View {
        settingsSection(title: "Data Management") {
            Button { showExportSheet = true } label: {
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 28))
                        .foregroundColor(Theme.primary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Export OPML")
                            .headlineMedium()
                            .foregroundColor(Theme.primary)
                        Text("Download your feed list as OPML")
                            .labelXSmall()
                            .foregroundColor(Theme.onSurfaceVariant)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassPanel()
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("feeds v0.1.0")
                .headlineMedium()
                .foregroundColor(Theme.primary.opacity(0.2))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
        .padding(.bottom, 32)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.outlineVariant)
                .frame(height: 1)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - OPML Export

    private func generateOPML() -> String {
        var lines = [
            """
            <?xml version="1.0" encoding="UTF-8"?>
            <opml version="2.0">
            <head><title>feeds export</title></head>
            <body>
            """
        ]
        for item in feedViewModel.menuItems {
            switch item {
            case .single(let feed):
                lines.append("  <outline text=\"\(escapeXML(feed.title))\" xmlUrl=\"\(escapeXML(feed.url))\" type=\"rss\"/>")
            case .group(_, let title, let feeds):
                lines.append("  <outline text=\"\(escapeXML(title))\">")
                for feed in feeds {
                    lines.append("    <outline text=\"\(escapeXML(feed.title))\" xmlUrl=\"\(escapeXML(feed.url))\" type=\"rss\"/>")
                }
                lines.append("  </outline>")
            }
        }
        lines.append("</body>\n</opml>")
        return lines.joined(separator: "\n")
    }

    private func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    // MARK: - Helpers

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .labelSmall()
                .foregroundColor(Theme.primary.opacity(0.5))
                .tracking(2)
            content()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Glass Panel Modifier

extension View {
    func glassPanel() -> some View {
        self
            .background(Theme.surfaceContainerLow.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.outlineVariant, lineWidth: 1)
            )
    }
}
