import SwiftUI

@main
struct NeuApp: App {
    @State private var store = CycleStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .tint(Theme.accent)
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }
            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
            HistoryView()
                .tabItem { Label("Cycles", systemImage: "circle.dotted") }
        }
    }
}
