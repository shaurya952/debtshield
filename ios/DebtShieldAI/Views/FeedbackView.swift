import SwiftUI
import UIKit

/// Privacy-preserving beta feedback.
///
/// The tester picks a type, writes a note, and chooses which **non-sensitive**
/// details to include. A live preview shows exactly what will be shared, and the
/// only action is "Copy" — nothing is sent automatically, and financial data
/// (income, expenses, debt, verdicts, county, simulation results) can never be
/// attached, by construction (`FeedbackReport` has no field for it).
struct FeedbackView: View {
    let store: MoneyPlanStore

    @State private var type: FeedbackType = .bug
    @State private var message = ""
    @State private var includeDevice = true
    @State private var includeAccessibility = false
    @State private var includeFeatures = false
    @State private var copied = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Form {
            Section("What kind of feedback?") {
                Picker("Type", selection: $type) {
                    ForEach(FeedbackType.allCases) { Text($0.rawValue).tag($0) }
                }
            }

            Section {
                ZStack(alignment: .topLeading) {
                    if message.isEmpty {
                        Text("What happened, or what would help? The more specific, the better.")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.secondaryText)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $message)
                        .frame(minHeight: 120)
                        .font(Theme.Typography.body)
                }
            } header: {
                Text("Describe it")
            } footer: {
                Text("Please don't type real dollar amounts you'd rather keep private — they're not needed to help.")
            }

            Section {
                Toggle("Device details (app, model, iOS)", isOn: $includeDevice)
                Toggle("Accessibility settings I'm using", isOn: $includeAccessibility)
                Toggle("Which features I've tried", isOn: $includeFeatures)
            } header: {
                Text("Include (optional)")
            } footer: {
                Text("Your income, rent, debt, verdicts, county, and simulation results are never included. You choose what to share, and nothing is sent automatically.")
            }

            Section("This is exactly what will be shared") {
                Text(report)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Theme.secondaryText)
            }

            Section {
                Button {
                    UIPasteboard.general.string = report
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { copied = false }
                    }
                } label: {
                    Label(copied ? "Copied to clipboard" : "Copy feedback",
                          systemImage: copied ? "checkmark.circle.fill" : "doc.on.doc")
                        .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
                }
                .buttonStyle(.borderedProminent)
                .sensoryFeedback(.success, trigger: copied)
            } footer: {
                Text("Copy this and paste it wherever you're sharing feedback (a message, an email, or an issue). A dedicated in-app send option will arrive with the Headroom website.")
            }
        }
        .navigationTitle("Send feedback")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var report: String {
        FeedbackReport.build(
            type: type,
            message: message,
            includeDevice: includeDevice,
            includeAccessibility: includeAccessibility,
            includeFeatures: includeFeatures,
            diagnostics: diagnostics
        )
    }

    private var diagnostics: FeedbackDiagnostics {
        var d = FeedbackDiagnostics()
        d.appVersion = DeviceInfo.appVersion
        d.deviceModel = DeviceInfo.model
        d.systemVersion = "iOS \(UIDevice.current.systemVersion)"
        d.textSize = String(describing: dynamicTypeSize)
        d.voiceOverOn = UIAccessibility.isVoiceOverRunning
        d.reduceMotionOn = UIAccessibility.isReduceMotionEnabled
        d.featuresTried = featuresTried
        return d
    }

    private var featuresTried: [String] {
        let d = UserDefaults.standard
        let r = RetentionState.from(
            historyKeys: store.history.map(\.monthKey),
            currentMonthKey: store.month,
            currentComplete: store.plan.isComplete,
            openedYearAhead: d.bool(forKey: "debtshield.opened.yearAhead"),
            openedComparison: d.bool(forKey: "debtshield.opened.comparison"),
            savedAnAction: d.bool(forKey: "debtshield.opened.saveEarn")
        )
        var out = ["Tracked \(r.monthsTracked) month\(r.monthsTracked == 1 ? "" : "s")"]
        if r.openedYearAhead { out.append("Opened the year-ahead") }
        if r.openedComparison { out.append("Opened compare") }
        if r.savedAnAction { out.append("Opened save & earn more") }
        return out
    }
}

/// Small, non-sensitive device facts for a beta report.
enum DeviceInfo {
    static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    static var model: String {
        if let sim = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return sim
        }
        var sys = utsname()
        uname(&sys)
        return withUnsafeBytes(of: &sys.machine) { raw in
            let ptr = raw.baseAddress!.assumingMemoryBound(to: CChar.self)
            return String(cString: ptr)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack { FeedbackView(store: .preview(.sampleTight)) }
}
#endif
