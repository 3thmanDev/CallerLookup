// Checks the number parser on the build machine before the app is built:
// swiftc CallerLookup/PhoneNumber.swift CallerLookup/LookupService.swift Tests/main.swift -o parser-check && ./parser-check

import Foundation

var failures = 0

func expect(_ input: String, digits: String?, display: String? = nil, title: String? = nil, line: Int = #line) {
    let number = PhoneNumber.parse(input)
    if number?.digits != digits {
        print("FAIL line \(line): \(input) -> \(number?.digits ?? "nil"), expected \(digits ?? "nil")")
        failures += 1
        return
    }
    if let display, number?.display != display {
        print("FAIL line \(line): \(input) displays \(number?.display ?? "nil"), expected \(display)")
        failures += 1
    }
    if let title, number?.title != title {
        print("FAIL line \(line): \(input) title \(number?.title ?? "nil"), expected \(title)")
        failures += 1
    }
}

// Saudi mobile in every common spelling.
expect("0501234567", digits: "966501234567", display: "050 123 4567", title: "جوال سعودي")
expect("501234567", digits: "966501234567")
expect("+966501234567", digits: "966501234567")
expect("+966 50 123 4567", digits: "966501234567")
expect("00966501234567", digits: "966501234567")
expect("966501234567", digits: "966501234567")
expect("+9660501234567", digits: "966501234567")
expect("٠٥٠١٢٣٤٥٦٧", digits: "966501234567")
expect("۰۵۰۱۲۳۴۵۶۷", digits: "966501234567")
expect("(050) 123-4567", digits: "966501234567")

// Other Saudi lines.
expect("0114123456", digits: "966114123456", display: "011 412 3456", title: "هاتف ثابت")
expect("920012345", digits: "966920012345", display: "9200 12345", title: "رقم موحد")
expect("8001245555", digits: "9668001245555", display: "800 124 5555", title: "رقم مجاني")
expect("911", digits: "911", display: "911", title: "الطوارئ الموحد")
expect("937", digits: "937", title: "وزارة الصحة")

// International.
expect("+971501234567", digits: "971501234567", display: "+971 501234567", title: "رقم من الإمارات")
expect("00447911123456", digits: "447911123456", title: "رقم من بريطانيا")
expect("+201001234567", digits: "201001234567", title: "رقم من مصر")
expect("+12025550123", digits: "12025550123", title: "رقم من أمريكا أو كندا")
expect("+911234567890", digits: "911234567890", title: "رقم من الهند")

// Not a full number.
expect("", digits: nil)
expect("abc", digits: nil)
expect("05012345", digits: nil)
expect("1234567", digits: nil)
expect("+12", digits: nil)

// Lookup links.
let mobile = PhoneNumber.parse("0501234567")!
let links = LookupService.allCases.compactMap { $0.url(for: mobile)?.absoluteString }
for link in links { print(link) }
if LookupService.whatsapp.url(for: mobile)?.absoluteString != "https://wa.me/966501234567" {
    print("FAIL: WhatsApp link")
    failures += 1
}
if LookupService.truecaller.url(for: mobile)?.absoluteString != "https://www.truecaller.com/search/sa/501234567" {
    print("FAIL: Truecaller link")
    failures += 1
}
if LookupService.whatsapp.url(for: PhoneNumber.parse("920012345")!) != nil {
    print("FAIL: unified numbers have no WhatsApp")
    failures += 1
}

print(failures == 0 ? "All parser checks passed" : "\(failures) parser checks failed")
exit(failures == 0 ? 0 : 1)
