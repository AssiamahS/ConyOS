import SwiftUI

@main
struct ConyOSApp: App {
    @StateObject private var store = ConyStore()

    var body: some Scene {
        WindowGroup {
            PingsView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(Market.green)
        }
    }
}

// One coherent system: near-black canvas, market-green as the single accent,
// market-red reserved for aging/overdue semantics. Numbers are rounded and
// monospaced-digit everywhere, like a portfolio screen.
enum Market {
    static let canvas = Color(red: 0.04, green: 0.04, blue: 0.05)
    static let card = Color.white.opacity(0.055)
    static let hairline = Color.white.opacity(0.07)
    static let green = Color(red: 0.19, green: 0.84, blue: 0.46)
    static let red = Color(red: 1.0, green: 0.27, blue: 0.23)
    static let amber = Color(red: 1.0, green: 0.65, blue: 0.15)
}
