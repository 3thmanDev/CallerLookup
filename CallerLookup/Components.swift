import SwiftUI

/// Wraps text in a left-to-right isolate so "+971 50..." doesn't get reversed inside Arabic text.
func ltr(_ text: String) -> String {
    "\u{2066}\(text)\u{2069}"
}

extension LookupService {
    var color: Color {
        switch self {
        case .truecaller: return Theme.truecaller
        case .whatsapp: return Theme.whatsapp
        case .telegram: return Theme.telegram
        case .google: return Theme.google
        }
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct FlagBadge: View {
    let number: PhoneNumber
    var size: CGFloat = 40

    var body: some View {
        Text(number.country?.flag ?? "🌐")
            .font(.system(size: size * 0.6))
            .frame(width: size, height: size)
            .background(Circle().fill(Theme.field))
    }
}

struct ServiceTile: View {
    let service: LookupService
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: service.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(service.color))
                    .padding(.bottom, 2)
                Text(service.name)
                    .font(.cairo(16, .bold))
                    .foregroundColor(Theme.ink)
                Text(service.hint)
                    .font(.cairo(12))
                    .foregroundColor(Theme.secondary)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.field))
        }
        .buttonStyle(PressableStyle())
    }
}

struct ActionButton: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(Theme.accent)
                    .frame(height: 26)
                Text(title)
                    .font(.cairo(13, .semibold))
                    .foregroundColor(Theme.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .card(cornerRadius: 18)
        }
        .buttonStyle(PressableStyle())
    }
}

struct StatusRow: View {
    let symbol: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 26))
                .foregroundColor(color)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.cairo(16, .bold))
                    .foregroundColor(Theme.ink)
                Text(subtitle)
                    .font(.cairo(13))
                    .foregroundColor(Theme.secondary)
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }
}

struct HistoryRow: View {
    let record: LookupRecord
    let number: PhoneNumber
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                FlagBadge(number: number)
                VStack(alignment: .leading, spacing: 0) {
                    Text(ltr(number.display))
                        .font(.cairo(17, .bold))
                        .foregroundColor(Theme.ink)
                    Text(record.note.isEmpty ? number.title : record.note)
                        .font(.cairo(13, .semibold))
                        .foregroundColor(record.note.isEmpty ? Theme.secondary : Theme.accent)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Text(Format.relative(record.date))
                    .font(.cairo(12))
                    .foregroundColor(Theme.secondary)
                    .lineLimit(1)
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.secondary.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
