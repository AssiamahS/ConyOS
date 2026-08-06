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
    // cloud relay — plain HTTPS, reachable from anywhere, no VPN needed
    @AppStorage("cloudURL") var cloudURL = "https://cony-relay.sylvesterassiamahpm.workers.dev"
    // the Mac on the tailnet — fresher when reachable, required for actions
    @AppStorage("serverURL") var serverURL = "http://100.97.199.99:8797"

    @Published var pings: [Ping] = []
    @Published var lastError: String?
    @Published var isLoading = false

    private static let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 10
        cfg.timeoutIntervalForResource = 15
        return URLSession(configuration: cfg)
    }()

    func refresh(preferMac: Bool = false) async {
        isLoading = true
        defer { isLoading = false }
        // right after an action the Mac is authoritative — the cloud copy
        // lags behind by one push
        if preferMac, let fresh = await fetchPings(serverURL + "/pings", key: nil) {
            pings = fresh
            lastError = nil
            return
        }
        for attempt in 1...2 {
            if let cloud = await fetchPings(cloudURL + "/items", key: ConySecrets.relayKey) {
                pings = cloud
                lastError = nil
                return
            }
            if let local = await fetchPings(serverURL + "/pings", key: nil) {
                pings = local
                lastError = nil
                return
            }
            if attempt == 1 { try? await Task.sleep(for: .seconds(2)) }
        }
        lastError = "Offline — couldn't reach cloud sync or the Mac."
    }

    private func fetchPings(_ urlString: String, key: String?) async -> [Ping]? {
        guard let url = URL(string: urlString) else { return nil }
        var req = URLRequest(url: url)
        if let key { req.setValue(key, forHTTPHeaderField: "x-app-key") }
        guard let (data, resp) = try? await Self.session.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let decoded = try? JSONDecoder().decode(PingsResponse.self, from: data)
        else { return nil }
        return decoded.pings
    }

    func post(_ path: String, body: [String: Any]) async {
        do {
            guard let url = URL(string: serverURL + path) else { return }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            _ = try await Self.session.data(for: req)
            await refresh(preferMac: true)
        } catch {
            lastError = "Change didn't save — actions need the Mac (Tailscale or home Wi-Fi)."
        }
    }

    func resolve(_ p: Ping) async { await post("/resolve", body: ["id": p.id]) }
    func snooze(_ p: Ping) async { await post("/snooze", body: ["id": p.id, "hours": 24]) }

    // Claude runs on the Mac; give it minutes, not seconds.
    func ask(_ p: Ping, question: String) async -> String {
        do {
            guard let url = URL(string: serverURL + "/ask") else { return "Bad server URL." }
            var req = URLRequest(url: url, timeoutInterval: 300)
            req.httpMethod = "POST"
            req.httpBody = try JSONSerialization.data(withJSONObject: ["id": p.id, "question": question])
            let cfg = URLSessionConfiguration.default
            cfg.timeoutIntervalForResource = 300
            let (data, _) = try await URLSession(configuration: cfg).data(for: req)
            let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return obj?["answer"] as? String ?? obj?["error"] as? String ?? "No answer came back."
        } catch {
            return "Couldn't reach Claude — asking needs the Mac (Tailscale or home Wi-Fi)."
        }
    }
}
