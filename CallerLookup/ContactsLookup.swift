import Contacts

enum ContactsAccess {
    case granted
    case notAsked
    case denied
}

/// Checks whether a number is already saved in the phone's own contacts.
enum ContactsLookup {
    static var access: ContactsAccess {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        if status == .authorized { return .granted }
        if #available(iOS 18.0, *), status == .limited { return .granted }
        return status == .notDetermined ? .notAsked : .denied
    }

    static func requestAccess() async -> Bool {
        (try? await CNContactStore().requestAccess(for: .contacts)) ?? false
    }

    /// Names of saved contacts that have this number in any of its spellings.
    static func names(for number: PhoneNumber) async -> [String] {
        let spellings = number.contactSpellings
        return await Task.detached(priority: .userInitiated) {
            let store = CNContactStore()
            let keys: [CNKeyDescriptor] = [
                CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                CNContactOrganizationNameKey as CNKeyDescriptor,
            ]
            var names: [String] = []
            for spelling in spellings {
                let predicate = CNContact.predicateForContacts(matching: CNPhoneNumber(stringValue: spelling))
                let contacts = (try? store.unifiedContacts(matching: predicate, keysToFetch: keys)) ?? []
                for contact in contacts {
                    let name = CNContactFormatter.string(from: contact, style: .fullName) ?? contact.organizationName
                    if !name.isEmpty && !names.contains(name) {
                        names.append(name)
                    }
                }
            }
            return names
        }.value
    }
}
