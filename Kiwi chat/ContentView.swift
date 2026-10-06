import SwiftUI

struct ContentView: View {
    @StateObject private var engine = MockLiveEngine()

    var body: some View {
        Group {
            if engine.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .environmentObject(engine)
    }
}

#Preview {
    ContentView()
}
