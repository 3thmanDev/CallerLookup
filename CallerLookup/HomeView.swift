import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var history: HistoryStore
    @State private var input = ""
    @State private var number: PhoneNumber?
    @State private var showsInvalid = false
    @State private var confirmsClear = false
    @FocusState private var fieldFocused: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    header
                        .id("top")
                    searchCard
                    if let number {
                        NumberResultView(number: number)
                            .id(number)
                            .transition(.opacity)
                    } else if showsInvalid {
                        invalidCard
                    }
                    if !history.records.isEmpty {
                        historySection(proxy: proxy)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 40)
                .animation(.easeOut(duration: 0.25), value: number)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Theme.background.ignoresSafeArea())
        .onChange(of: input) { newInput in
            showsInvalid = false
            // Typing a different number hides the old result until you search again.
            if number != nil && PhoneNumber.parse(newInput) != number {
                number = nil
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text("مين المتصل؟")
                    .font(.cairo(30, .black))
                Text("اكتب الرقم أو الصقه وشوف صاحبه")
                    .font(.cairo(14, .medium))
                    .foregroundColor(Theme.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "phone.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(Theme.accent)
        }
        .padding(.top, 12)
    }

    private var searchCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                TextField("05XXXXXXXX", text: $input)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .font(.cairo(26, .bold))
                    .multilineTextAlignment(.center)
                    .focused($fieldFocused)
                    .environment(\.layoutDirection, .leftToRight)
                if !input.isEmpty {
                    Button {
                        input = ""
                        number = nil
                        fieldFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Theme.secondary.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 66)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.field))

            HStack(spacing: 10) {
                Button(action: search) {
                    Label("ابحث", systemImage: "magnifyingglass")
                        .font(.cairo(17, .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Capsule().fill(Theme.accent))
                }
                .buttonStyle(PressableStyle())

                PasteButton(payloadType: String.self) { strings in
                    guard let text = strings.first else { return }
                    DispatchQueue.main.async {
                        input = text
                        search()
                    }
                }
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .tint(Theme.ink)
            }
        }
        .padding(16)
        .card()
    }

    private var invalidCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundColor(Theme.orange)
            VStack(alignment: .leading, spacing: 0) {
                Text("الرقم ناقص أو مو واضح")
                    .font(.cairo(16, .bold))
                Text("اكتبه مثل \(ltr("0501234567")) أو \(ltr("+966501234567"))")
                    .font(.cairo(13))
                    .foregroundColor(Theme.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .card()
    }

    private func historySection(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("آخر الأرقام")
                    .font(.cairo(18, .bold))
                Spacer()
                Button("مسح الكل") {
                    confirmsClear = true
                }
                .font(.cairo(14, .semibold))
                .foregroundColor(Theme.red)
            }
            .padding(.horizontal, 4)

            LazyVStack(spacing: 0) {
                ForEach(history.records) { record in
                    if let recordNumber = record.number {
                        HistoryRow(record: record, number: recordNumber) {
                            open(recordNumber, proxy: proxy)
                        }
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = recordNumber.compactLocal
                            } label: {
                                Label("نسخ الرقم", systemImage: "doc.on.doc")
                            }
                            Button(role: .destructive) {
                                history.delete(record)
                            } label: {
                                Label("حذف من السجل", systemImage: "trash")
                            }
                        }
                        if record.id != history.records.last?.id {
                            Divider()
                                .padding(.leading, 66)
                        }
                    }
                }
            }
            .card()
        }
        .confirmationDialog("تمسح كل الأرقام وملاحظاتها؟", isPresented: $confirmsClear, titleVisibility: .visible) {
            Button("مسح الكل", role: .destructive) {
                history.clear()
            }
            Button("إلغاء", role: .cancel) {}
        }
    }

    private func search() {
        guard let parsed = PhoneNumber.parse(input) else {
            number = nil
            showsInvalid = !input.isEmpty
            return
        }
        fieldFocused = false
        showsInvalid = false
        number = parsed
        history.record(parsed)
    }

    private func open(_ recordNumber: PhoneNumber, proxy: ScrollViewProxy) {
        input = recordNumber.compactLocal
        fieldFocused = false
        number = recordNumber
        history.record(recordNumber)
        withAnimation {
            proxy.scrollTo("top", anchor: .top)
        }
    }
}
