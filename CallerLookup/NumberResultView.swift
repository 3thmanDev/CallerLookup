import SwiftUI
import UIKit

enum ContactMatch: Equatable {
    case checking
    case found([String])
    case notFound
    case notAsked
    case denied
}

/// Everything about one number: what kind it is, whether you saved it, and where to look it up.
struct NumberResultView: View {
    let number: PhoneNumber

    @EnvironmentObject private var history: HistoryStore
    @Environment(\.openURL) private var openURL
    @State private var contactMatch: ContactMatch = .checking
    @State private var note = ""
    @State private var showsNewContact = false
    @State private var copied = false

    private var services: [LookupService] {
        LookupService.allCases.filter { $0.url(for: number) != nil }
    }

    var body: some View {
        VStack(spacing: 16) {
            identityCard
            if !services.isEmpty {
                servicesCard
            }
            actionsRow
            noteCard
        }
        .task {
            note = history.note(for: number)
            await refreshContacts()
        }
        .sheet(isPresented: $showsNewContact) {
            NewContactSheet(phone: number.dialString) {
                showsNewContact = false
                Task { await refreshContacts() }
            }
            .ignoresSafeArea()
        }
    }

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                FlagBadge(number: number, size: 58)
                VStack(alignment: .leading, spacing: 0) {
                    Text(ltr(number.display))
                        .font(.cairo(25, .black))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text(number.title)
                        .font(.cairo(15, .bold))
                        .foregroundColor(Theme.accent)
                }
                Spacer(minLength: 0)
            }
            Text(number.detail)
                .font(.cairo(14))
                .foregroundColor(Theme.body)
                .fixedSize(horizontal: false, vertical: true)
            Divider()
            contactRow
        }
        .padding(18)
        .card()
    }

    @ViewBuilder
    private var contactRow: some View {
        switch contactMatch {
        case .checking:
            HStack(spacing: 12) {
                ProgressView()
                    .frame(width: 34)
                Text("ندوّر في جهات اتصالك...")
                    .font(.cairo(14))
                    .foregroundColor(Theme.secondary)
                Spacer(minLength: 0)
            }
        case .found(let names):
            StatusRow(
                symbol: "person.crop.circle.fill.badge.checkmark",
                color: Theme.green,
                title: names.joined(separator: "، "),
                subtitle: "محفوظ عندك في جهات الاتصال"
            )
        case .notFound:
            StatusRow(
                symbol: "person.crop.circle.badge.xmark",
                color: Theme.secondary,
                title: "مو محفوظ عندك",
                subtitle: "ما لقيناه في جهات اتصالك"
            )
        case .notAsked:
            Button {
                Task {
                    _ = await ContactsLookup.requestAccess()
                    await refreshContacts()
                }
            } label: {
                StatusRow(
                    symbol: "person.crop.circle.badge.questionmark",
                    color: Theme.accent,
                    title: "شيك هل هو محفوظ عندك",
                    subtitle: "اضغط هنا واسمح بالوصول لجهات الاتصال"
                )
            }
            .buttonStyle(.plain)
        case .denied:
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                StatusRow(
                    symbol: "lock.circle",
                    color: Theme.orange,
                    title: "الوصول لجهات الاتصال مقفل",
                    subtitle: "اضغط عشان تفتحه من الإعدادات"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var servicesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("اعرف صاحب الرقم من")
                .font(.cairo(17, .bold))
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(services) { service in
                    ServiceTile(service: service) {
                        if let url = service.url(for: number) {
                            openURL(url)
                        }
                    }
                }
            }
            Text("تروكولر يطلب تسجيل دخول أول مرة. واتساب وتيليجرام يوضحون الاسم والصورة بس لو صاحب الرقم سامح فيها.")
                .font(.cairo(12))
                .foregroundColor(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .card()
    }

    private var actionsRow: some View {
        HStack(spacing: 10) {
            ActionButton(title: "اتصال", symbol: "phone.fill") {
                open("tel:\(number.dialString)")
            }
            if !number.isService {
                ActionButton(title: "رسالة", symbol: "message.fill") {
                    open("sms:\(number.dialString)")
                }
            }
            ActionButton(title: copied ? "انتسخ" : "نسخ", symbol: copied ? "checkmark" : "doc.on.doc") {
                copy()
            }
            ActionButton(title: "حفظ", symbol: "person.badge.plus") {
                showsNewContact = true
            }
        }
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("ملاحظتك على الرقم", systemImage: "note.text")
                .font(.cairo(16, .bold))
            TextField("مثلاً: مندوب توصيل، إزعاج، شركة...", text: $note)
                .font(.cairo(16))
                .submitLabel(.done)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.field))
            Text("تطلع لك الملاحظة في السجل كل ما رجعت للرقم.")
                .font(.cairo(12))
                .foregroundColor(Theme.secondary)
        }
        .padding(18)
        .card()
        .onChange(of: note) { newNote in
            history.setNote(newNote, for: number)
        }
    }

    private func open(_ link: String) {
        guard let url = URL(string: link) else { return }
        openURL(url)
    }

    private func copy() {
        UIPasteboard.general.string = number.compactLocal
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copied = false
        }
    }

    private func refreshContacts() async {
        switch ContactsLookup.access {
        case .granted:
            contactMatch = .checking
            let names = await ContactsLookup.names(for: number)
            contactMatch = names.isEmpty ? .notFound : .found(names)
        case .notAsked:
            contactMatch = .notAsked
        case .denied:
            contactMatch = .denied
        }
    }
}
