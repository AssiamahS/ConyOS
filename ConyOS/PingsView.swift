import SwiftUI

struct PingsView: View {
    @EnvironmentObject var store: ConyStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.08, green: 0.06, blue: 0.1), .black],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    header
                    if let err = store.lastError {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                    if store.pings.isEmpty && store.lastError == nil {
                        emptyState
                    }
                    ForEach(store.pings) { p in
                        PingRow(ping: p)
                    }
                }
                .padding(20)
            }
            .refreshable { await store.refresh() }
        }
        .task { await store.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await store.refresh() } }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Cony")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(store.pings.isEmpty
                     ? "Nobody is waiting on you"
                     : "\(store.pings.count) waiting on you")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "hare.fill")
                .font(.system(size: 26))
                .foregroundStyle(Cony.gradient)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 42))
                .foregroundStyle(Cony.mint)
            Text("Nothing is falling through the cracks.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 80)
    }
}

struct PingRow: View {
    @EnvironmentObject var store: ConyStore
    let ping: Ping

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: ping.icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Cony.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(ping.who)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if let what = ping.what, !what.isEmpty {
                    Text(what)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Text(ping.waitingLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle((ping.hours_waiting ?? 0) >= 24 ? Cony.coral : Color.secondary)
            }
            Spacer(minLength: 0)

            Button {
                Task { await store.resolve(ping) }
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Cony.mint)
            }
        }
        .padding(14)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contextMenu {
            Button("Snooze 24h") { Task { await store.snooze(ping) } }
        }
    }
}
