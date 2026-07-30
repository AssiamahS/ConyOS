import SwiftUI

@main
struct ConyOSApp: App {
    @StateObject private var store = ConyStore()

    var body: some Scene {
        WindowGroup {
            PingsView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(Cony.coral)
        }
    }
}

enum Cony {
    // matches the logo: coral-to-orange gradient, white rabbit
    static let coral = Color(red: 0.95, green: 0.42, blue: 0.36)
    static let orange = Color(red: 0.97, green: 0.58, blue: 0.31)
    static let gradient = LinearGradient(
        colors: [coral, orange],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let mint = Color(red: 0.35, green: 0.85, blue: 0.65)
}
