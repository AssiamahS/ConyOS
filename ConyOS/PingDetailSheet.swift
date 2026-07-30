import SwiftUI

struct PingDetailSheet: View {
    @EnvironmentObject var store: ConyStore
    @Environment(\.dismiss) private var dismiss

    let ping: Ping

    @State private var replyTo = ""
    @State private var replyText = ""
    @State private var sending = false
    @State private var sent = false
    @State private var question = ""
    @State private var asking = false
    @State private var answer: String?

    private var canSend: Bool {
        !sending && !replyText.trimmingCharacters(in: .whitespaces).isEmpty
            && replyTo.contains("@")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red: 0.08, green: 0.06, blue: 0.1), .black],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        whatCard
                        if ping.channel == "email" || replyTo.contains("@") {
                            replyCard
                        }
                        askClaudeCard
                        actionRow
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Ping")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            replyTo = ping.reply_to ?? (ping.who.contains("@") ? ping.who : "")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: ping.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Cony.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(ping.who)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text("\(ping.channel) · \(ping.waitingLabel)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle((ping.hours_waiting ?? 0) >= 24 ? Cony.coral : Color.secondary)
            }
            Spacer()
        }
    }

    private var whatCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("WHAT THEY'RE WAITING FOR")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .kerning(1.2)
            Text(ping.what?.isEmpty == false ? ping.what! : "No details — you know this one.")
                .font(.subheadline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var replyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("REPLY AS YOU")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .kerning(1.2)
            TextField("to@address.com", text: $replyTo)
                .font(.caption)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(.secondary)
            TextField("Type the reply, it sends from your real email…", text: $replyText, axis: .vertical)
                .lineLimit(3...8)
                .foregroundStyle(.white)
            Button(action: send) {
                HStack {
                    if sending { ProgressView().tint(.white) }
                    Text(sent ? "Sent ✓" : sending ? "Sending…" : "Send reply")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    canSend || sent ? AnyShapeStyle(Cony.gradient) : AnyShapeStyle(Color.white.opacity(0.1)),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            }
            .disabled(!canSend)
        }
        .padding(16)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var askClaudeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ASK CLAUDE")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .kerning(1.2)
            TextField("Research this, draft a reply, what should I do…", text: $question, axis: .vertical)
                .lineLimit(1...4)
                .foregroundStyle(.white)
            Button {
                let q = question.trimmingCharacters(in: .whitespaces)
                guard !q.isEmpty, !asking else { return }
                asking = true
                answer = nil
                Task {
                    answer = await store.ask(ping, question: q)
                    asking = false
                }
            } label: {
                HStack {
                    if asking { ProgressView().tint(.white) }
                    Text(asking ? "Claude is working…" : "Ask")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    question.trimmingCharacters(in: .whitespaces).isEmpty || asking
                        ? AnyShapeStyle(Color.white.opacity(0.1))
                        : AnyShapeStyle(Cony.gradient),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            }
            .disabled(question.trimmingCharacters(in: .whitespaces).isEmpty || asking)
            if let a = answer {
                Text(a)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .textSelection(.enabled)
                    .padding(12)
                    .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button {
                Task { await store.resolve(ping); dismiss() }
            } label: {
                Label("Done", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Cony.mint.opacity(0.25), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            Button {
                Task { await store.snooze(ping); dismiss() }
            } label: {
                Label("Snooze 24h", systemImage: "moon.zzz.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private func send() {
        sending = true
        Task {
            await store.post("/reply", body: [
                "id": ping.id,
                "to": replyTo.trimmingCharacters(in: .whitespaces),
                "body": replyText,
            ])
            sending = false
            sent = true
            try? await Task.sleep(for: .seconds(1))
            dismiss()
        }
    }
}
