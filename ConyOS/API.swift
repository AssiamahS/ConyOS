import Foundation
import SwiftUI

struct Ping: Codable, Identifiable, Hashable {
    let id: String
    var channel: String
    var who: String
    var what: String?
    var since: String?
    var status: String
    var hours_waiting: Double?
    var reply_to: String?

    var waitingLabel: String {
        guard let h = hours_waiting else { return "" }
        if h >= 48 { return "\(Int((h / 24).rounded()))d waiting" }
        return "\(Int(h.rounded()))h waiting"
    }

    var icon: String {
        switch channel {
        case "imessage", "sms": return "message.fill"
        case "email": return "envelope.fill"
        case "telegram": return "paperplane.fill"
        case "whatsapp": return "phone.bubble.fill"
        case "instagram": return "camera.fill"
        case "call": return "phone.fill"
        default: return "bell.fill"
        }
    }
}

struct PingsResponse: Codable { var pings: [Ping] }

@MainActor
final class ConyStore: ObservableObject {
    @AppStorage("serverURL") var serverURL = "http://100.97.199.99:8797"

    @Published var pings: [Ping] = []
    @Published var lastError: String?
    @Published var isLoading = false

    private static let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.waitsForConnectivity = true
        cfg.timeoutIntervalForResource = 20
        return URLSession(configuration: cfg)
    }()

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        for attempt in 1...3 {
            do {
                guard let url = URL(string: serverURL + "/pings") else { throw URLError(.badURL) }
                let (data, _) = try await Self.session.data(from: url)
                pings = try JSONDecoder().decode(PingsResponse.self, from: data).pings
                lastError = nil
                return
            } catch {
                if attempt == 3 { lastError = "Can't reach the Mac. Check Tailscale." }
                else { try? await Task.sleep(for: .seconds(2)) }
            }
        }
    }

    func post(_ path: String, body: [String: Any]) async {
        do {
            guard let url = URL(string: serverURL + path) else { return }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            _ = try await Self.session.data(for: req)
            await refresh()
        } catch {
            lastError = "Change didn't save. Try again."
        }
    }

    func resolve(_ p: Ping) async { await post("/resolve", body: ["id": p.id]) }
    func snooze(_ p: Ping) async { await post("/snooze", body: ["id": p.id, "hours": 24]) }
}
