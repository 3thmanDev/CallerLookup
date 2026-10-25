import SwiftUI

enum Theme {
    static let background = Color(red: 0.937, green: 0.941, blue: 0.957)
    static let card = Color.white
    static let ink = Color(red: 0.13, green: 0.14, blue: 0.18)
    static let body = Color(red: 0.30, green: 0.31, blue: 0.35)
    static let secondary = Color(red: 0.55, green: 0.56, blue: 0.60)
    static let field = Color(red: 0.953, green: 0.957, blue: 0.969)
    static let divider = Color(red: 0.90, green: 0.90, blue: 0.92)

    static let accent = Color(red: 0.16, green: 0.42, blue: 0.95)
    static let truecaller = Color(red: 0.0, green: 0.46, blue: 1.0)
    static let whatsapp = Color(red: 0.15, green: 0.73, blue: 0.40)
    static let telegram = Color(red: 0.16, green: 0.63, blue: 0.87)
    static let google = Color(red: 0.92, green: 0.30, blue: 0.24)
    static let green = Color(red: 0.20, green: 0.70, blue: 0.38)
    static let orange = Color(red: 0.96, green: 0.58, blue: 0.16)
    static let red = Color(red: 0.92, green: 0.30, blue: 0.28)
}

enum CairoWeight: String {
    case regular = "Cairo-Regular"
    case medium = "Cairo-Medium"
    case semibold = "Cairo-SemiBold"
    case bold = "Cairo-Bold"
    case extraBold = "Cairo-ExtraBold"
    case black = "Cairo-Black"
}

extension Font {
    static func cairo(_ size: CGFloat, _ weight: CairoWeight = .regular) -> Font {
        .custom(weight.rawValue, size: size)
    }
}

extension View {
    func card(cornerRadius: CGFloat = 24) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Theme.card)
                .shadow(color: Color.black.opacity(0.04), radius: 14, x: 0, y: 4)
        )
    }

    /// Arabic right-to-left layout, Cairo font and the light look, applied to the root and every sheet.
    func appEnvironment() -> some View {
        font(.cairo(17))
            .foregroundColor(Theme.ink)
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.locale, Format.locale)
            .preferredColorScheme(.light)
    }
}

enum Format {
    static let locale = Locale(identifier: "ar@numbers=latn")

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.unitsStyle = .full
        return formatter
    }()

    static func relative(_ date: Date) -> String {
        relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}
