import SwiftUI

enum AppColors {
    static let background = Color(red: 0, green: 0.035, blue: 0.078)
    static let cardBackground = Color.white.opacity(0.04)
    static let cardBorder = Color.white.opacity(0.08)
    static let primary = Color(red: 0, green: 0.412, blue: 0.8)
    static let primaryDark = Color(red: 0, green: 0.333, blue: 0.643)
    static let accent = Color(red: 0, green: 0.412, blue: 0.8)
    static let destructive = Color(red: 0.937, green: 0.255, blue: 0.208)
    static let success = Color(red: 0.2, green: 0.78, blue: 0.35)
    static let warning = Color(red: 1, green: 0.75, blue: 0)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.5)
    static let textTertiary = Color.white.opacity(0.3)

    static let primaryGradient = LinearGradient(
        colors: [primary, primaryDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let backgroundGradient = RadialGradient(
        colors: [
            Color(red: 0.039, green: 0.176, blue: 0.361),
            Color(red: 0, green: 0.106, blue: 0.239),
            Color(red: 0, green: 0.031, blue: 0.078)
        ],
        center: .init(x: 0.1, y: 0.5),
        startRadius: 0,
        endRadius: 600
    )
}

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial.opacity(0.3))
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
}
