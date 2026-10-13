import SwiftUI
import UIKit

enum Theme {
    static let background = dynamic(light: (0.969, 0.953, 0.925), dark: (0.075, 0.07, 0.065))
    static let surface    = dynamic(light: (0.941, 0.918, 0.882), dark: (0.125, 0.115, 0.105))
    static let ink        = dynamic(light: (0.145, 0.133, 0.122), dark: (0.93, 0.915, 0.89))
    static let muted      = dynamic(light: (0.48, 0.45, 0.42), dark: (0.62, 0.59, 0.56))
    static let accent     = dynamic(light: (0.78, 0.36, 0.25), dark: (0.88, 0.50, 0.38))

    private static func dynamic(light: (Double, Double, Double), dark: (Double, Double, Double)) -> Color {
        Color(UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
    }

    static func title(_ size: CGFloat) -> Font { .system(size: size, weight: .light, design: .serif) }
    static let caption = Font.system(size: 12, weight: .regular).smallCaps()
}

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(Theme.ink)
            .background(Theme.background.ignoresSafeArea())
    }
}

extension View {
    func screen() -> some View { modifier(ScreenBackground()) }
}

struct Pill: ViewModifier {
    var selected: Bool
    func body(content: Content) -> some View {
        content
            .font(.system(size: 14))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selected ? Theme.accent : Theme.surface, in: Capsule())
            .foregroundStyle(selected ? Color.white : Theme.ink)
    }
}

extension View {
    func pill(selected: Bool) -> some View { modifier(Pill(selected: selected)) }
}
