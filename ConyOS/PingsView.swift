import SwiftUI
import UIKit

struct PingsView: View {
    @EnvironmentObject var store: ConyStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var selected: Ping?

    var body: some View {
        ZStack {
            Market.canvas.ignoresSafeArea()

            List {
                Group {
                    header
                    statusRibbon
                    if let err = store.lastError {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(Market.amber)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 2, leading: 20, bottom: 6, trailing: 20))

                if store.pings.isEmpty {
                    emptyState
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                ForEach(store.pings) { p in
                    TickerRow(ping: p)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                        .contentShape(Rectangle())
                        .onTapGesture { selected = p }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                Task { await store.resolve(p) }
                            } label: {
                                Label("Done", systemImage: "checkmark")
                            }
                            .tint(Market.green)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                Task { await store.snooze(p) }
                            } label: {
                                Label("24h", systemImage: "moon.zzz.fill")
                            }
                            .tint(.indigo)
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .refreshable { await store.refresh() }
        }
        .task { await store.refresh() }
        .sheet(item: $selected) { PingDetailSheet(ping: $0) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await store.refresh() } }
        }
    }

    // MARK: portfolio-style headline

    private var newToday: Int {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(identifier: "UTC")
        let today = fmt.string(from: Date())
        return store.pings.filter { $0.created == today }.count
    }

    private var overdue: Int {
        store.pings.filter { ($0.hours_waiting ?? 0) >= 48 }.count
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("WAITING ON YOU")
                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                    .kerning(1.5)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "hare.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Market.green)
            }
            .padding(.top, 8)

            Text("\(store.pings.count)")
                .font(.system(size: 76, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            deltaLine
        }
    }

    private var deltaLine: some View {
        HStack(spacing: 12) {
            if newToday > 0 {
                Text("▲ \(newToday) new today")
                    .foregroundStyle(Market.green)
            }
            if overdue > 0 {
                Text("\(overdue) overdue")
                    .foregroundStyle(Market.red)
            }
            if newToday == 0 && overdue == 0 {
                Text(store.pings.isEmpty ? "all clear" : "holding steady")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.system(.footnote, design: .rounded).weight(.semibold))
        .monospacedDigit()
    }

    // MARK: market-status ribbon

    private var statusRibbon: some View {
        HStack(spacing: 7) {
            switch store.connection {
            case .live(let source):
                Circle().fill(Market.green).frame(width: 7, height: 7)
                Text("LIVE · \(source)")
                    .foregroundStyle(Market.green)
            case .offline(let last):
                Circle().fill(Market.red).frame(width: 7, height: 7)
                Text(offlineLabel(last))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if store.isLoading { ProgressView().controlSize(.mini) }
        }
        .font(.system(.caption2, design: .monospaced).weight(.semibold))
        .kerning(0.8)
    }

    private func offlineLabel(_ last: Date?) -> String {
        guard let last else { return "OFFLINE — NO SYNC YET" }
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return "OFFLINE — SHOWING \(fmt.string(from: last))"
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 42))
                .foregroundStyle(Market.green)
            Text("Nothing is falling through the cracks.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 70)
    }
}

// MARK: - ticker row

struct TickerRow: View {
    let ping: Ping

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(ping.symbol)
                    .font(.system(.caption2, design: .monospaced).weight(.bold))
                    .kerning(0.8)
                    .foregroundStyle(.secondary)
                Text(ping.who)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if let what = ping.what, !what.isEmpty {
                    Text(what)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 8)

            Text(ping.ageBadge)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(badgeForeground)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(badgeBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(14)
        .background(Market.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Market.hairline, lineWidth: 1)
        )
    }

    private var hours: Double { ping.hours_waiting ?? 0 }

    private var badgeForeground: Color {
        if hours >= 48 { return Market.red }
        if hours >= 24 { return Market.amber }
        return .white.opacity(0.85)
    }

    private var badgeBackground: Color {
        if hours >= 48 { return Market.red.opacity(0.16) }
        if hours >= 24 { return Market.amber.opacity(0.15) }
        return .white.opacity(0.08)
    }
}
