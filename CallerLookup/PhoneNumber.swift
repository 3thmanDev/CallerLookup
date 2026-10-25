import Foundation

struct Country: Hashable {
    let callingCode: String
    let iso: String
    let name: String

    var flag: String {
        iso.uppercased().unicodeScalars
            .compactMap { UnicodeScalar(127397 + $0.value) }
            .map { String(Character($0)) }
            .joined()
    }

    static let saudi = Country(callingCode: "966", iso: "sa", name: "السعودية")

    static let all: [Country] = [
        saudi,
        Country(callingCode: "971", iso: "ae", name: "الإمارات"),
        Country(callingCode: "965", iso: "kw", name: "الكويت"),
        Country(callingCode: "973", iso: "bh", name: "البحرين"),
        Country(callingCode: "974", iso: "qa", name: "قطر"),
        Country(callingCode: "968", iso: "om", name: "عُمان"),
        Country(callingCode: "967", iso: "ye", name: "اليمن"),
        Country(callingCode: "964", iso: "iq", name: "العراق"),
        Country(callingCode: "962", iso: "jo", name: "الأردن"),
        Country(callingCode: "963", iso: "sy", name: "سوريا"),
        Country(callingCode: "961", iso: "lb", name: "لبنان"),
        Country(callingCode: "970", iso: "ps", name: "فلسطين"),
        Country(callingCode: "20", iso: "eg", name: "مصر"),
        Country(callingCode: "249", iso: "sd", name: "السودان"),
        Country(callingCode: "218", iso: "ly", name: "ليبيا"),
        Country(callingCode: "216", iso: "tn", name: "تونس"),
        Country(callingCode: "213", iso: "dz", name: "الجزائر"),
        Country(callingCode: "212", iso: "ma", name: "المغرب"),
        Country(callingCode: "222", iso: "mr", name: "موريتانيا"),
        Country(callingCode: "252", iso: "so", name: "الصومال"),
        Country(callingCode: "251", iso: "et", name: "إثيوبيا"),
        Country(callingCode: "254", iso: "ke", name: "كينيا"),
        Country(callingCode: "256", iso: "ug", name: "أوغندا"),
        Country(callingCode: "234", iso: "ng", name: "نيجيريا"),
        Country(callingCode: "27", iso: "za", name: "جنوب أفريقيا"),
        Country(callingCode: "90", iso: "tr", name: "تركيا"),
        Country(callingCode: "98", iso: "ir", name: "إيران"),
        Country(callingCode: "92", iso: "pk", name: "باكستان"),
        Country(callingCode: "91", iso: "in", name: "الهند"),
        Country(callingCode: "880", iso: "bd", name: "بنغلاديش"),
        Country(callingCode: "977", iso: "np", name: "نيبال"),
        Country(callingCode: "94", iso: "lk", name: "سريلانكا"),
        Country(callingCode: "93", iso: "af", name: "أفغانستان"),
        Country(callingCode: "63", iso: "ph", name: "الفلبين"),
        Country(callingCode: "62", iso: "id", name: "إندونيسيا"),
        Country(callingCode: "60", iso: "my", name: "ماليزيا"),
        Country(callingCode: "66", iso: "th", name: "تايلاند"),
        Country(callingCode: "84", iso: "vn", name: "فيتنام"),
        Country(callingCode: "86", iso: "cn", name: "الصين"),
        Country(callingCode: "82", iso: "kr", name: "كوريا الجنوبية"),
        Country(callingCode: "81", iso: "jp", name: "اليابان"),
        Country(callingCode: "61", iso: "au", name: "أستراليا"),
        Country(callingCode: "44", iso: "gb", name: "بريطانيا"),
        Country(callingCode: "33", iso: "fr", name: "فرنسا"),
        Country(callingCode: "49", iso: "de", name: "ألمانيا"),
        Country(callingCode: "39", iso: "it", name: "إيطاليا"),
        Country(callingCode: "34", iso: "es", name: "إسبانيا"),
        Country(callingCode: "31", iso: "nl", name: "هولندا"),
        Country(callingCode: "46", iso: "se", name: "السويد"),
        Country(callingCode: "7", iso: "ru", name: "روسيا"),
        Country(callingCode: "1", iso: "us", name: "أمريكا أو كندا"),
    ]

    /// The longest matching calling code wins, so 971 is never read as a shorter code.
    static func matching(_ digits: String) -> Country? {
        all.filter { digits.hasPrefix($0.callingCode) }
            .max { $0.callingCode.count < $1.callingCode.count }
    }
}

enum NumberKind: Hashable {
    case saudiMobile(carrier: String?)
    case saudiLandline(region: String)
    case saudiUnified
    case saudiTollFree
    case saudiService(name: String)
    case international
}

struct PhoneNumber: Hashable {
    /// Full international digits without "+", e.g. 966501234567. Short service numbers keep just their digits.
    let digits: String
    let country: Country?
    /// The number after the country code and without the trunk 0, e.g. 501234567.
    let national: String
    let kind: NumberKind

    var isService: Bool {
        if case .saudiService = kind { return true }
        return false
    }

    var isSaudi: Bool { country == Country.saudi }

    /// Text that parses back to this same number; stored in the history.
    var canonical: String { isService ? digits : "+" + digits }

    var dialString: String { isService ? digits : "+" + digits }

    /// How people in Saudi write it (050 123 4567), or +code number for other countries.
    var display: String {
        let chars = Array(national)
        func part(_ from: Int, _ to: Int) -> String { String(chars[from..<min(to, chars.count)]) }

        switch kind {
        case .saudiMobile, .saudiLandline:
            return "0\(part(0, 2)) \(part(2, 5)) \(part(5, chars.count))"
        case .saudiUnified:
            return "\(part(0, 4)) \(part(4, chars.count))"
        case .saudiTollFree:
            return "\(part(0, 3)) \(part(3, 6)) \(part(6, chars.count))"
        case .saudiService:
            return digits
        case .international:
            guard let country else { return "+" + digits }
            return "+\(country.callingCode) \(national)"
        }
    }

    /// Short local form without spaces, the one people paste into WhatsApp or search boxes.
    var compactLocal: String {
        switch kind {
        case .saudiMobile, .saudiLandline: return "0" + national
        case .saudiUnified, .saudiTollFree, .saudiService: return national
        case .international: return "+" + digits
        }
    }

    var title: String {
        switch kind {
        case .saudiMobile: return "جوال سعودي"
        case .saudiLandline: return "هاتف ثابت"
        case .saudiUnified: return "رقم موحد"
        case .saudiTollFree: return "رقم مجاني"
        case .saudiService(let name): return name
        case .international: return country.map { "رقم من \($0.name)" } ?? "رقم دولي"
        }
    }

    var detail: String {
        switch kind {
        case .saudiMobile(let carrier):
            guard let carrier else { return "شبكة غير معروفة" }
            return "بادئته الأصلية لـ \(carrier)، وممكن يكون نقل لشركة ثانية"
        case .saudiLandline(let region):
            return region
        case .saudiUnified:
            return "غالباً لشركة أو جهة حكومية (9200)"
        case .saudiTollFree:
            return "خدمة عملاء لشركة أو جهة (800)"
        case .saudiService:
            return "رقم خدمة رسمي في السعودية"
        case .international:
            guard let country else { return "ما عرفنا الدولة من مفتاح الرقم" }
            return "مفتاح الدولة +\(country.callingCode)"
        }
    }

    /// Spellings of the number to look for on the web, since pages write it in different ways.
    var searchSpellings: [String] {
        switch kind {
        case .saudiMobile, .saudiLandline:
            return ["0" + national, digits, "+" + digits]
        case .saudiUnified, .saudiTollFree, .saudiService:
            return [national]
        case .international:
            return [digits, "+" + digits]
        }
    }

    /// Spellings that may be saved in the phone's contacts.
    var contactSpellings: [String] {
        isSaudi && !isService ? ["+" + digits, "0" + national, national] : [dialString]
    }

    /// Who can be found by number on chat apps: not service, unified or toll-free lines.
    var canHaveChatAccount: Bool {
        switch kind {
        case .saudiMobile, .saudiLandline, .international: return true
        case .saudiUnified, .saudiTollFree, .saudiService: return false
        }
    }
}

extension PhoneNumber {
    static let saudiServices: [String: String] = [
        "911": "الطوارئ الموحد",
        "999": "الشرطة",
        "998": "الدفاع المدني",
        "997": "الهلال الأحمر",
        "996": "أمن الطرق",
        "993": "المرور",
        "937": "وزارة الصحة",
        "940": "بلاغات البلديات",
    ]

    static let saudiCarriers: [String: String] = [
        "50": "STC", "53": "STC", "55": "STC",
        "54": "موبايلي", "56": "موبايلي",
        "58": "زين", "59": "زين",
        "57": "شبكة افتراضية مثل فيرجن وليبارا",
    ]

    static let saudiRegions: [String: String] = [
        "11": "الرياض والمنطقة الوسطى",
        "12": "مكة وجدة والطائف",
        "13": "المنطقة الشرقية",
        "14": "المدينة وتبوك والشمال",
        "16": "القصيم وحائل",
        "17": "عسير وجازان ونجران والباحة",
    ]

    /// Keeps a leading "+" and the digits, turning Arabic-Indic and Persian digits into Latin ones.
    static func cleaned(_ text: String) -> String {
        var result = ""
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x30...0x39:
                result.unicodeScalars.append(scalar)
            case 0x660...0x669:
                result.unicodeScalars.append(UnicodeScalar(scalar.value - 0x660 + 0x30)!)
            case 0x6F0...0x6F9:
                result.unicodeScalars.append(UnicodeScalar(scalar.value - 0x6F0 + 0x30)!)
            case 0x2B where result.isEmpty:
                result.append("+")
            default:
                continue
            }
        }
        return result
    }

    static func parse(_ text: String) -> PhoneNumber? {
        let cleanedText = cleaned(text)
        let hasPlus = cleanedText.hasPrefix("+")
        var digits = hasPlus ? String(cleanedText.dropFirst()) : cleanedText
        guard !digits.isEmpty else { return nil }

        if !hasPlus, let service = saudiServices[digits] {
            return PhoneNumber(digits: digits, country: Country.saudi, national: digits, kind: .saudiService(name: service))
        }

        var isInternational = hasPlus
        if !isInternational && digits.hasPrefix("00") {
            digits.removeFirst(2)
            isInternational = true
        }
        // 9665XXXXXXXX written without + or 00.
        if !isInternational && digits.hasPrefix("966") && digits.count >= 12 {
            isInternational = true
        }

        guard isInternational else { return saudi(national: digits) }
        guard (7...15).contains(digits.count) else { return nil }

        guard let country = Country.matching(digits) else {
            return PhoneNumber(digits: digits, country: nil, national: digits, kind: .international)
        }
        let national = String(digits.dropFirst(country.callingCode.count))
        if country == Country.saudi { return saudi(national: national) }
        return PhoneNumber(digits: digits, country: country, national: national, kind: .international)
    }

    private static func saudi(national raw: String) -> PhoneNumber? {
        // Drops the trunk 0, including the common slip of writing +9660 5...
        let national = raw.hasPrefix("0") ? String(raw.dropFirst()) : raw
        guard let kind = saudiKind(national) else { return nil }
        return PhoneNumber(digits: "966" + national, country: Country.saudi, national: national, kind: kind)
    }

    private static func saudiKind(_ national: String) -> NumberKind? {
        let prefix = String(national.prefix(2))
        switch national.count {
        case 9 where national.hasPrefix("5"):
            return .saudiMobile(carrier: saudiCarriers[prefix])
        case 9 where national.hasPrefix("1"):
            return .saudiLandline(region: saudiRegions[prefix] ?? "هاتف ثابت في السعودية")
        case 9 where national.hasPrefix("920"):
            return .saudiUnified
        case 10 where national.hasPrefix("800"):
            return .saudiTollFree
        default:
            return nil
        }
    }
}
