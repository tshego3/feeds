import SwiftUI

// MARK: - Theme Color Palette

struct ThemeColors {
    let isDark: Bool
    let background: Color
    let surface: Color
    let surfaceDim: Color
    let surfaceBright: Color
    let surfaceContainerLowest: Color
    let surfaceContainerLow: Color
    let surfaceContainer: Color
    let surfaceContainerHigh: Color
    let surfaceContainerHighest: Color
    let surfaceVariant: Color
    let onSurface: Color
    let onSurfaceVariant: Color
    let onBackground: Color
    let primary: Color
    let onPrimary: Color
    let primaryContainer: Color
    let onPrimaryContainer: Color
    let secondary: Color
    let onSecondary: Color
    let secondaryContainer: Color
    let onSecondaryContainer: Color
    let outline: Color
    let outlineVariant: Color
    let error: Color
    let onError: Color
    let errorContainer: Color
    let inverseSurface: Color
    let inverseOnSurface: Color
}

// MARK: - Theme Presets

extension ThemeColors {

    /// Standard light appearance — white surfaces, dark text, iOS system-style colors.
    static let light = ThemeColors(
        isDark: false,
        background: Color(hex: 0xF8F8FA),
        surface: Color(hex: 0xFFFFFF),
        surfaceDim: Color(hex: 0xF0F0F2),
        surfaceBright: Color(hex: 0xFFFFFF),
        surfaceContainerLowest: Color(hex: 0xFFFFFF),
        surfaceContainerLow: Color(hex: 0xF5F5F7),
        surfaceContainer: Color(hex: 0xEFEFF1),
        surfaceContainerHigh: Color(hex: 0xE8E8EA),
        surfaceContainerHighest: Color(hex: 0xE0E0E2),
        surfaceVariant: Color(hex: 0xE0E0E2),
        onSurface: Color(hex: 0x1C1C1E),
        onSurfaceVariant: Color(hex: 0x636366),
        onBackground: Color(hex: 0x1C1C1E),
        primary: Color(hex: 0x000000),
        onPrimary: Color(hex: 0xFFFFFF),
        primaryContainer: Color(hex: 0xE5E5EA),
        onPrimaryContainer: Color(hex: 0x3C3C43),
        secondary: Color(hex: 0x8E8E93),
        onSecondary: Color(hex: 0xFFFFFF),
        secondaryContainer: Color(hex: 0xE5E5EA),
        onSecondaryContainer: Color(hex: 0x636366),
        outline: Color(hex: 0xAEAEB2),
        outlineVariant: Color(hex: 0xD1D1D6),
        error: Color(hex: 0xFF3B30),
        onError: Color(hex: 0xFFFFFF),
        errorContainer: Color(hex: 0xFFE5E3),
        inverseSurface: Color(hex: 0x2C2C2E),
        inverseOnSurface: Color(hex: 0xF2F2F7)
    )

    /// Dark appearance — Monolithic Clarity design system palette.
    /// Charcoal surfaces, off-white text, desaturated and architectural.
    static let dark = ThemeColors(
        isDark: true,
        background: Color(hex: 0x131313),
        surface: Color(hex: 0x131313),
        surfaceDim: Color(hex: 0x131313),
        surfaceBright: Color(hex: 0x393939),
        surfaceContainerLowest: Color(hex: 0x0E0E0E),
        surfaceContainerLow: Color(hex: 0x1C1B1B),
        surfaceContainer: Color(hex: 0x201F1F),
        surfaceContainerHigh: Color(hex: 0x2A2A2A),
        surfaceContainerHighest: Color(hex: 0x353534),
        surfaceVariant: Color(hex: 0x353534),
        onSurface: Color(hex: 0xE5E2E1),
        onSurfaceVariant: Color(hex: 0xC4C7C8),
        onBackground: Color(hex: 0xE5E2E1),
        primary: Color.white,
        onPrimary: Color(hex: 0x2F3131),
        primaryContainer: Color(hex: 0xE2E2E2),
        onPrimaryContainer: Color(hex: 0x636565),
        secondary: Color(hex: 0xC8C6C6),
        onSecondary: Color(hex: 0x303030),
        secondaryContainer: Color(hex: 0x474747),
        onSecondaryContainer: Color(hex: 0xB6B5B4),
        outline: Color(hex: 0x8E9192),
        outlineVariant: Color(hex: 0x444748),
        error: Color(hex: 0xFFB4AB),
        onError: Color(hex: 0x690005),
        errorContainer: Color(hex: 0x93000A),
        inverseSurface: Color(hex: 0xE5E2E1),
        inverseOnSurface: Color(hex: 0x313030)
    )

    /// Monochrome — high-contrast OLED black mode. Pure black surfaces, pure white text,
    /// maximum contrast ratio. Minimal tonal layering for true-black displays.
    static let monochrome = ThemeColors(
        isDark: true,
        background: Color(hex: 0x000000),
        surface: Color(hex: 0x000000),
        surfaceDim: Color(hex: 0x000000),
        surfaceBright: Color(hex: 0x2A2A2A),
        surfaceContainerLowest: Color(hex: 0x000000),
        surfaceContainerLow: Color(hex: 0x0F0F0F),
        surfaceContainer: Color(hex: 0x141414),
        surfaceContainerHigh: Color(hex: 0x1A1A1A),
        surfaceContainerHighest: Color(hex: 0x222222),
        surfaceVariant: Color(hex: 0x222222),
        onSurface: Color(hex: 0xFFFFFF),
        onSurfaceVariant: Color(hex: 0xB0B0B0),
        onBackground: Color(hex: 0xFFFFFF),
        primary: Color.white,
        onPrimary: Color(hex: 0x000000),
        primaryContainer: Color(hex: 0xE0E0E0),
        onPrimaryContainer: Color(hex: 0x404040),
        secondary: Color(hex: 0xB0B0B0),
        onSecondary: Color(hex: 0x000000),
        secondaryContainer: Color(hex: 0x2A2A2A),
        onSecondaryContainer: Color(hex: 0xB0B0B0),
        outline: Color(hex: 0x666666),
        outlineVariant: Color(hex: 0x333333),
        error: Color(hex: 0xFF6B6B),
        onError: Color(hex: 0x000000),
        errorContainer: Color(hex: 0x440000),
        inverseSurface: Color(hex: 0xFFFFFF),
        inverseOnSurface: Color(hex: 0x000000)
    )
}

// MARK: - Theme Accessor (Monolithic Clarity Design System)

enum Theme {

    nonisolated(unsafe) static var current: ThemeColors = .monochrome

    static func apply(_ theme: String) {
        switch theme {
        case "Light": current = .light
        case "Dark": current = .dark
        case "Monochrome": current = .monochrome
        default: current = .dark
        }
    }

    // MARK: - Surface Colors (Tonal Depth Layers)

    static var background: Color { current.background }
    static var surface: Color { current.surface }
    static var surfaceDim: Color { current.surfaceDim }
    static var surfaceBright: Color { current.surfaceBright }
    static var surfaceContainerLowest: Color { current.surfaceContainerLowest }
    static var surfaceContainerLow: Color { current.surfaceContainerLow }
    static var surfaceContainer: Color { current.surfaceContainer }
    static var surfaceContainerHigh: Color { current.surfaceContainerHigh }
    static var surfaceContainerHighest: Color { current.surfaceContainerHighest }
    static var surfaceVariant: Color { current.surfaceVariant }

    // MARK: - Content Colors

    static var onSurface: Color { current.onSurface }
    static var onSurfaceVariant: Color { current.onSurfaceVariant }
    static var onBackground: Color { current.onBackground }

    // MARK: - Primary

    static var primary: Color { current.primary }
    static var onPrimary: Color { current.onPrimary }
    static var primaryContainer: Color { current.primaryContainer }
    static var onPrimaryContainer: Color { current.onPrimaryContainer }

    // MARK: - Secondary

    static var secondary: Color { current.secondary }
    static var onSecondary: Color { current.onSecondary }
    static var secondaryContainer: Color { current.secondaryContainer }
    static var onSecondaryContainer: Color { current.onSecondaryContainer }

    // MARK: - Outline

    static var outline: Color { current.outline }
    static var outlineVariant: Color { current.outlineVariant }

    // MARK: - Error

    static var error: Color { current.error }
    static var onError: Color { current.onError }
    static var errorContainer: Color { current.errorContainer }

    // MARK: - Inverse

    static var inverseSurface: Color { current.inverseSurface }
    static var inverseOnSurface: Color { current.inverseOnSurface }

    // MARK: - Derived

    static var isDark: Bool { current.isDark }
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

// MARK: - Typography Modifiers

extension View {
    func headlineLarge() -> some View {
        self.font(.system(size: 32, weight: .semibold, design: .default))
            .tracking(-0.64)
    }

    func headlineMedium() -> some View {
        self.font(.system(size: 20, weight: .medium, design: .default))
            .tracking(-0.2)
    }

    func bodyLarge() -> some View {
        self.font(.system(size: 17, weight: .regular, design: .default))
            .lineSpacing(17 * 0.6)
    }

    func bodyMedium() -> some View {
        self.font(.system(size: 15, weight: .regular, design: .default))
            .lineSpacing(15 * 0.6)
    }

    func labelSmall() -> some View {
        self.font(.system(size: 13, weight: .medium, design: .default))
            .tracking(0.26)
    }

    func labelXSmall() -> some View {
        self.font(.system(size: 11, weight: .semibold, design: .default))
            .tracking(0.55)
    }

    func serifBody(scale: Double = 1.0) -> some View {
        let size = 20 * scale
        return self.font(.system(size: size, weight: .regular, design: .serif))
            .lineSpacing(size * 0.8)
    }
}
