import Foundation

/// Outside services that can tell who owns a number. The app only opens them; it never collects data itself.
enum LookupService: CaseIterable, Identifiable {
    case truecaller
    case whatsapp
    case telegram
    case google

    var id: Self { self }

    var name: String {
        switch self {
        case .truecaller: return "تروكولر"
        case .whatsapp: return "واتساب"
        case .telegram: return "تيليجرام"
        case .google: return "قوقل"
        }
    }

    var hint: String {
        switch self {
        case .truecaller: return "الاسم اللي مسجل فيه عند الناس"
        case .whatsapp: return "الاسم والصورة لو كانت ظاهرة"
        case .telegram: return "الحساب لو سامح يلقونه برقمه"
        case .google: return "إعلانات ومواقع منشور فيها الرقم"
        }
    }

    var symbol: String {
        switch self {
        case .truecaller: return "person.crop.circle.badge.questionmark"
        case .whatsapp: return "message.fill"
        case .telegram: return "paperplane.fill"
        case .google: return "magnifyingglass"
        }
    }

    func url(for number: PhoneNumber) -> URL? {
        switch self {
        case .truecaller:
            guard let country = number.country, !number.isService else { return nil }
            return URL(string: "https://www.truecaller.com/search/\(country.iso)/\(number.national)")
        case .whatsapp:
            guard number.canHaveChatAccount else { return nil }
            return URL(string: "https://wa.me/\(number.digits)")
        case .telegram:
            guard number.canHaveChatAccount else { return nil }
            return URL(string: "https://t.me/+\(number.digits)")
        case .google:
            guard !number.isService else { return nil }
            let query = number.searchSpellings.map { "\"\($0)\"" }.joined(separator: " OR ")
            guard var components = URLComponents(string: "https://www.google.com/search") else { return nil }
            components.queryItems = [URLQueryItem(name: "q", value: query)]
            // URLComponents leaves "+" as is, and Google would read it as a space.
            let encodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
            components.percentEncodedQuery = encodedQuery
            return components.url
        }
    }
}
