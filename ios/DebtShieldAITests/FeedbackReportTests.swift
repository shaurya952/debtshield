import XCTest
@testable import DebtShieldAI

/// The beta-feedback report builder. The critical property: it can only ever
/// contain what the tester chose — never financial data (the type has no field
/// for it), and diagnostics appear only when their toggle is on.
final class FeedbackReportTests: XCTestCase {

    private func sampleDiagnostics() -> FeedbackDiagnostics {
        FeedbackDiagnostics(
            appVersion: "1.0 (1)",
            deviceModel: "iPhone17,1",
            systemVersion: "iOS 26.5",
            textSize: "large",
            voiceOverOn: false,
            reduceMotionOn: true,
            featuresTried: ["Tracked 2 months", "Opened the year-ahead"]
        )
    }

    func testIncludesTypeAndMessage() {
        let r = FeedbackReport.build(type: .bug, message: "The odds card looked wrong",
                                     includeDevice: false, includeAccessibility: false,
                                     includeFeatures: false, diagnostics: sampleDiagnostics())
        XCTAssertTrue(r.contains("Type: Bug"))
        XCTAssertTrue(r.contains("The odds card looked wrong"))
    }

    func testDeviceOnlyWhenIncluded() {
        let off = FeedbackReport.build(type: .bug, message: "x", includeDevice: false,
                                       includeAccessibility: false, includeFeatures: false,
                                       diagnostics: sampleDiagnostics())
        XCTAssertFalse(off.contains("iPhone17,1"))
        let on = FeedbackReport.build(type: .bug, message: "x", includeDevice: true,
                                      includeAccessibility: false, includeFeatures: false,
                                      diagnostics: sampleDiagnostics())
        XCTAssertTrue(on.contains("iPhone17,1"))
        XCTAssertTrue(on.contains("iOS 26.5"))
    }

    func testAccessibilityOnlyWhenIncluded() {
        let on = FeedbackReport.build(type: .accessibility, message: "x", includeDevice: false,
                                      includeAccessibility: true, includeFeatures: false,
                                      diagnostics: sampleDiagnostics())
        XCTAssertTrue(on.contains("Reduce Motion: on"))
        XCTAssertTrue(on.contains("VoiceOver: off"))
        let off = FeedbackReport.build(type: .accessibility, message: "x", includeDevice: false,
                                       includeAccessibility: false, includeFeatures: false,
                                       diagnostics: sampleDiagnostics())
        XCTAssertFalse(off.contains("Reduce Motion"))
    }

    func testFeaturesOnlyWhenIncluded() {
        let on = FeedbackReport.build(type: .other, message: "x", includeDevice: false,
                                      includeAccessibility: false, includeFeatures: true,
                                      diagnostics: sampleDiagnostics())
        XCTAssertTrue(on.contains("Tracked 2 months"))
        let off = FeedbackReport.build(type: .other, message: "x", includeDevice: false,
                                       includeAccessibility: false, includeFeatures: false,
                                       diagnostics: sampleDiagnostics())
        XCTAssertFalse(off.contains("Tracked 2 months"))
    }

    func testAlwaysCarriesTheNoFinancialsAssurance() {
        let r = FeedbackReport.build(type: .bug, message: "", includeDevice: true,
                                     includeAccessibility: true, includeFeatures: true,
                                     diagnostics: sampleDiagnostics())
        XCTAssertTrue(r.contains("No income, expenses, debt, verdicts, county, or simulation results"))
    }

    func testEmptyMessageIsHandled() {
        let r = FeedbackReport.build(type: .feature, message: "   ", includeDevice: false,
                                     includeAccessibility: false, includeFeatures: false,
                                     diagnostics: sampleDiagnostics())
        XCTAssertTrue(r.contains("(no description)"))
    }
}
