import SwiftUI

@main
struct CallerLookupApp: App {
    @StateObject private var history = HistoryStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(history)
                .appEnvironment()
        }
    }
}
