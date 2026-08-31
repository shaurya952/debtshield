import Foundation

/// The kind of feedback a beta tester is sending.
enum FeedbackType: String, CaseIterable, Identifiable, Sendable {
    case bug = "Bug"
    case confusing = "Confusing result"
    case accessibility = "Accessibility issue"
    case benchmark = "Incorrect benchmark"
    case feature = "Feature request"
    case other = "Other"

    var id: String { rawValue }
}

/// Non-sensitive diagnostics a tester may *choose* to include. There is
/// deliberately **no field here for financial data** — income, expenses, debt,
/// verdicts, county, and simulation results can never be attached, by
/// construction (see `CLAUDE.md`).
struct FeedbackDiagnostics: Equatable, Sendable {
    var appVersion: String = ""
    var deviceModel: String = ""
    var systemVersion: String = ""
    // Accessibility settings — included only with explicit consent.
    var textSize: String? = nil
    var voiceOverOn: Bool? = nil
    var reduceMotionOn: Bool? = nil
    // Which parts of the app have been tried (engagement, not finances).
    var featuresTried: [String] = []
}

/// Assembles the exact text a tester will copy/share. Pure and synchronous, so
/// the "this is exactly what will be shared" preview and the copied text are the
/// same string, and so it can be unit-tested.
enum FeedbackReport {
    static func build(
        type: FeedbackType,
        message: String,
        includeDevice: Bool,
        includeAccessibility: Bool,
        includeFeatures: Bool,
        diagnostics: FeedbackDiagnostics
    ) -> String {
        var lines: [String] = []
        lines.append("Headroom feedback")
        lines.append("Type: \(type.rawValue)")
        lines.append("")
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        lines.append(trimmed.isEmpty ? "(no description)" : trimmed)

        if includeDevice {
            lines.append("")
            lines.append("— Device —")
            lines.append("App: \(diagnostics.appVersion)")
            lines.append("Device: \(diagnostics.deviceModel)")
            lines.append("iOS: \(diagnostics.systemVersion)")
        }

        if includeAccessibility {
            var a11y: [String] = []
            if let t = diagnostics.textSize { a11y.append("Text size: \(t)") }
            if let v = diagnostics.voiceOverOn { a11y.append("VoiceOver: \(v ? "on" : "off")") }
            if let r = diagnostics.reduceMotionOn { a11y.append("Reduce Motion: \(r ? "on" : "off")") }
            if !a11y.isEmpty {
                lines.append("")
                lines.append("— Accessibility —")
                lines.append(contentsOf: a11y)
            }
        }

        if includeFeatures, !diagnostics.featuresTried.isEmpty {
            lines.append("")
            lines.append("— Progress —")
            diagnostics.featuresTried.forEach { lines.append("• \($0)") }
        }

        lines.append("")
        lines.append("(No income, expenses, debt, verdicts, county, or simulation results are included.)")
        return lines.joined(separator: "\n")
    }
}
