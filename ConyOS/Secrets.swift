// Stamped in CI: the TestFlight job replaces the placeholder with the real
// relay app key (CONY_APP_KEY repo secret) before xcodegen runs, so the key
// never lives in the repo. Local/simulator builds keep the placeholder —
// the relay answers 401 and the app falls back to the Mac over Tailscale.
enum ConySecrets {
    static let relayKey = "__CONY_APP_KEY__"
}
