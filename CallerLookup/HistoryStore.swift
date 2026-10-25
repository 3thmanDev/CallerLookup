import Foundation

struct LookupRecord: Codable, Identifiable, Equatable {
    var id = UUID()
    /// Parses back to the number with `PhoneNumber.parse`.
    let query: String
    var note: String
    var date: Date

    var number: PhoneNumber? { PhoneNumber.parse(query) }
}

/// Numbers you looked up and the notes you wrote on them, kept on the phone only.
final class HistoryStore: ObservableObject {
    @Published private(set) var records: [LookupRecord] = []

    private let storageKey = "lookupHistory"
    private let limit = 200

    init() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([LookupRecord].self, from: data) else { return }
        records = saved
    }

    /// Moves the number to the top, keeping any note written on it before.
    func record(_ number: PhoneNumber) {
        var record = records.first { $0.query == number.canonical }
            ?? LookupRecord(query: number.canonical, note: "", date: Date())
        record.date = Date()
        records.removeAll { $0.query == number.canonical }
        records.insert(record, at: 0)
        if records.count > limit {
            records.removeLast(records.count - limit)
        }
        save()
    }

    func note(for number: PhoneNumber) -> String {
        records.first { $0.query == number.canonical }?.note ?? ""
    }

    func setNote(_ note: String, for number: PhoneNumber) {
        guard let index = records.firstIndex(where: { $0.query == number.canonical }),
              records[index].note != note else { return }
        records[index].note = note
        save()
    }

    func delete(_ record: LookupRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }

    func clear() {
        records.removeAll()
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
