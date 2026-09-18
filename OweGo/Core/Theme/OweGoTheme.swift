import SwiftUI
import UIKit

enum OweGoTheme {
    // Fixed light palette — avoids dark-mode system colors clashing with cream background
    static let primary = Color(red: 0.106, green: 0.420, blue: 0.416)
    static let secondary = Color(red: 0.910, green: 0.455, blue: 0.310)
    static let surface = Color(red: 0.969, green: 0.961, blue: 0.949)
    static let card = Color.white
    static let cardMuted = Color(red: 0.96, green: 0.955, blue: 0.945)
    static let textPrimary = Color(red: 0.12, green: 0.14, blue: 0.16)
    static let textSecondary = Color(red: 0.45, green: 0.47, blue: 0.50)
    static let positive = Color(red: 0.18, green: 0.58, blue: 0.42)
    static let negative = Color(red: 0.85, green: 0.52, blue: 0.12)
    static let positiveBackground = Color(red: 0.88, green: 0.96, blue: 0.91)
    static let border = Color(red: 0.88, green: 0.87, blue: 0.85)

    static let cardRadius: CGFloat = 16
    static let cardShadow = Color.black.opacity(0.08)
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.82)

    static func moneyFont(size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [primary, Color(red: 0.145, green: 0.520, blue: 0.500)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Soft white diagonal wash for depth on gradient heroes.
    static var heroOverlay: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.22),
                Color.white.opacity(0.0),
                Color.black.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var softHeroWash: LinearGradient {
        LinearGradient(
            colors: [primary.opacity(0.07), Color.clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct OweGoCardModifier: ViewModifier {
    var muted: Bool = false

    func body(content: Content) -> some View {
        content
            .background(muted ? OweGoTheme.cardMuted : OweGoTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: OweGoTheme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: OweGoTheme.cardRadius, style: .continuous)
                    .stroke(OweGoTheme.border, lineWidth: 0.5)
            )
            .shadow(color: OweGoTheme.cardShadow, radius: 6, x: 0, y: 2)
    }
}

struct OweGoUpcomingCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(OweGoTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: OweGoTheme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: OweGoTheme.cardRadius, style: .continuous)
                    .stroke(OweGoTheme.primary.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: OweGoTheme.primary.opacity(0.12), radius: 10, x: 0, y: 4)
    }
}

struct OweGoPastCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(OweGoTheme.cardMuted)
            .clipShape(RoundedRectangle(cornerRadius: OweGoTheme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: OweGoTheme.cardRadius, style: .continuous)
                    .stroke(OweGoTheme.border.opacity(0.7), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
    }
}

struct OweGoLayeredBackground: View {
    var body: some View {
        ZStack {
            OweGoTheme.surface
            RadialGradient(
                colors: [
                    OweGoTheme.primary.opacity(0.14),
                    OweGoTheme.primary.opacity(0.04),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 380
            )
            .offset(y: -40)
            RadialGradient(
                colors: [
                    OweGoTheme.secondary.opacity(0.06),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 10,
                endRadius: 280
            )
        }
        .ignoresSafeArea()
    }
}

extension View {
    func owegoCard(muted: Bool = false) -> some View {
        modifier(OweGoCardModifier(muted: muted))
    }

    func owegoUpcomingCard() -> some View {
        modifier(OweGoUpcomingCardModifier())
    }

    func owegoPastCard() -> some View {
        modifier(OweGoPastCardModifier())
    }

    func owegoScreenBackground() -> some View {
        background { OweGoLayeredBackground() }
    }
}

enum Haptic {
    static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
}
