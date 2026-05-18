import SwiftUI

/// Settings view — account, appearance, preferences, data management.
/// Matches settings/code.html design with glassmorphic cards.
struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsViewModel
    @EnvironmentObject private var modelManager: ModelManagerViewModel
    @ObservedObject var feedViewModel: FeedViewModel
    @State private var showExportSheet = false
    @Environment(\.themeColors) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                headerSection
                appearanceSection
                preferencesSection
                aiModelSection
                dataManagementSection
                footerSection
            }
            .frame(maxWidth: 720)
            .padding(.bottom, 80)
        }
        .frame(maxWidth: .infinity)
        .background(theme.background)
        .sheet(isPresented: $showExportSheet) {
            let opml = feedViewModel.generateOPML()
            ShareSheet(activityItems: [opml])
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .headlineLarge()
                .foregroundColor(theme.primary)
            Text("Configure your reading experience and account preferences.")
                .bodyMedium()
                .foregroundColor(theme.onSurfaceVariant)
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
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
                    .background(theme.surfaceContainerHigh)
                    .foregroundColor(theme.onSurface)
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
                                settings.selectedTheme == "Auto" ? theme.primary : Color.clear,
                                lineWidth: 2
                            )
                    )
                Text("Auto")
                    .labelXSmall()
                    .foregroundColor(settings.selectedTheme == "Auto" ? theme.primary : theme.onSurfaceVariant)
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
                                settings.selectedTheme == name ? theme.primary : Color.clear,
                                lineWidth: 2
                            )
                    )
                Text(name)
                    .labelXSmall()
                    .foregroundColor(settings.selectedTheme == name ? theme.primary : theme.onSurfaceVariant)
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

                Rectangle().fill(theme.outlineVariant).frame(height: 1)

                preferenceToggle(
                    title: "Mark as Read on Scroll",
                    subtitle: "Automatically clear items as they leave the viewport",
                    isOn: $settings.markReadOnScroll
                )

                Rectangle().fill(theme.outlineVariant).frame(height: 1)

                preferenceToggle(
                    title: "Show AI Summaries",
                    subtitle: "Display AI-generated article summaries in the reader",
                    isOn: $settings.showAISummaries
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
                    .foregroundColor(theme.onSurface)
                Text(subtitle)
                    .labelXSmall()
                    .foregroundColor(theme.onSurfaceVariant)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(theme.primary)
        }
        .padding(16)
    }

    // MARK: - AI Model Management

    private var aiModelSection: some View {
        settingsSection(title: "AI Summaries") {
            VStack(spacing: 0) {
                if !modelManager.isMLXAvailable {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(theme.outline)
                        Text("AI summaries require Apple Silicon (iOS/macOS).")
                            .bodyMedium()
                            .foregroundColor(theme.onSurfaceVariant)
                    }
                    .padding(16)
                } else {
                    // Active model indicator
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("On-Device Model")
                                .bodyMedium()
                                .foregroundColor(theme.onSurface)
                            Text(modelManager.activeModel?.name ?? "No model selected")
                                .labelXSmall()
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                        Spacer()
                        if modelManager.isModelLoaded {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(16)

                    Rectangle().fill(theme.outlineVariant).frame(height: 1)

                    // Model list
                    ForEach(modelManager.availableModels) { model in
                        aiModelRow(model)
                        if model.id != modelManager.availableModels.last?.id {
                            Rectangle().fill(theme.outlineVariant.opacity(0.3)).frame(height: 1)
                                .padding(.leading, 16)
                        }
                    }
                }
            }
            .glassPanel()
        }
    }

    private func aiModelRow(_ model: AIModelInfo) -> some View {
        let isActive = modelManager.activeModelID == model.id
        let isDownloaded = modelManager.downloadedModelIDs.contains(model.id)
        let isDownloading = modelManager.downloadingModelID == model.id

        return Button {
            Task { await modelManager.downloadAndActivate(model) }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(model.name)
                            .bodyMedium()
                            .foregroundColor(isActive ? theme.primary : theme.onSurface)
                        Text(model.sizeLabel)
                            .labelXSmall()
                            .foregroundColor(theme.outline)
                    }
                    Text(model.description)
                        .labelXSmall()
                        .foregroundColor(theme.onSurfaceVariant)
                }

                Spacer()

                if isDownloading {
                    ProgressView(value: modelManager.downloadProgress)
                        .frame(width: 40)
                        .tint(theme.primary)
                } else if isActive && modelManager.isModelLoaded {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(theme.primary)
                } else if isDownloaded {
                    Image(systemName: "arrow.clockwise.circle")
                        .foregroundColor(theme.onSurfaceVariant)
                } else {
                    Image(systemName: "arrow.down.circle")
                        .foregroundColor(theme.onSurfaceVariant)
                }

                if isDownloaded && !isDownloading {
                    Button(role: .destructive) {
                        modelManager.deleteModel(model)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(theme.error)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .disabled(modelManager.isDownloading)
    }

    // MARK: - Data Management

    private var dataManagementSection: some View {
        settingsSection(title: "Data Management") {
            Button { showExportSheet = true } label: {
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 28))
                        .foregroundColor(theme.primary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Export OPML")
                            .headlineMedium()
                            .foregroundColor(theme.primary)
                        Text("Download your feed list as OPML")
                            .labelXSmall()
                            .foregroundColor(theme.onSurfaceVariant)
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
            Text("feeds v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0")")
                .headlineMedium()
                .foregroundColor(theme.primary.opacity(0.2))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
        .padding(.bottom, 32)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(theme.outlineVariant)
                .frame(height: 1)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .labelSmall()
                .foregroundColor(theme.primary.opacity(0.5))
                .tracking(2)
            content()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Glass Panel Modifier

struct GlassPanelModifier: ViewModifier {
    @Environment(\.themeColors) private var theme

    func body(content: Content) -> some View {
        content
            .background(theme.surfaceContainerLow.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.outlineVariant, lineWidth: 1)
            )
    }
}

extension View {
    func glassPanel() -> some View {
        self.modifier(GlassPanelModifier())
    }
}
