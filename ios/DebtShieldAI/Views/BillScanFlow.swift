import SwiftUI
import PhotosUI
import Vision
import VisionKit

/// The on-device "scan a bill to fill in a number" flow.
///
/// Everything here runs on the phone: Apple's document scanner (or a photo you
/// pick) becomes an image, Apple's Vision framework reads the text, and
/// `BillScanner` pulls out the dollar amounts. No image, no text, and no number
/// ever leaves the device — the scan is a keyboard shortcut, not an upload.

// MARK: - Fields a scanned amount can fill

/// The monthly fields a scanned amount can be dropped into. Kept in the app's own
/// plain words, matching the labels on the numbers form.
enum ScanField: String, CaseIterable, Identifiable {
    case income = "Money coming in"
    case housing = "Rent / mortgage"
    case homeUpkeep = "Home upkeep"
    case food = "Food"
    case energy = "Energy"
    case transportation = "Transport"
    case personal = "Personal"
    case debt = "Debt payment"
    case debtBalance = "Total you owe"

    var id: String { rawValue }
}

// MARK: - Vision OCR (on-device)

enum BillOCR {
    /// Reads the text off each image with Vision, on-device. Returns everything
    /// found, newline-joined, for `BillScanner` to mine for amounts.
    static func text(from images: [UIImage]) async -> String {
        await Task.detached(priority: .userInitiated) {
            var collected: [String] = []
            for image in images {
                guard let cg = image.cgImage else { continue }
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = false
                let handler = VNImageRequestHandler(cgImage: cg,
                                                    orientation: cgOrientation(image.imageOrientation))
                do {
                    try handler.perform([request])
                    let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
                    collected.append(contentsOf: lines)
                } catch {
                    // A page that can't be read just contributes nothing.
                }
            }
            return collected.joined(separator: "\n")
        }.value
    }

    private static func cgOrientation(_ o: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch o {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}

// MARK: - Document scanner (camera)

/// Thin wrapper around Apple's `VNDocumentCameraViewController` — the same
/// edge-detecting scanner as the Notes app. Camera only, so it's offered only
/// where a camera exists (`VNDocumentCameraViewController.isSupported`).
struct DocumentScannerView: UIViewControllerRepresentable {
    var onScan: ([UIImage]) -> Void
    var onCancel: () -> Void

    /// Whether this device can scan with the camera (false on the Simulator, where
    /// the photo-picker path is offered instead).
    static var isCameraScanSupported: Bool { VNDocumentCameraViewController.isSupported }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView
        init(_ parent: DocumentScannerView) { self.parent = parent }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for page in 0..<scan.pageCount { images.append(scan.imageOfPage(at: page)) }
            parent.onScan(images)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            parent.onCancel()
        }
    }
}

// MARK: - The "what did we find" sheet

/// Shows the amounts the scan found and lets a person tap each into a field.
/// Nothing is applied automatically — the reader always chooses.
struct ScannedAmountsSheet: View {
    let amounts: [Decimal]
    /// Called when a person assigns an amount to a field. The `Double` matches the
    /// form's field type.
    var onAssign: (ScanField, Double) -> Void

    @Environment(\.dismiss) private var dismiss
    /// Amounts already placed, so each shows a check and the list feels responsive.
    @State private var placed: Set<Decimal> = []

    var body: some View {
        NavigationStack {
            Group {
                if amounts.isEmpty {
                    ContentUnavailableView(
                        "No amounts found",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("We couldn't read a dollar figure from that. Try a clearer, well-lit photo — or just type it in.")
                    )
                } else {
                    List {
                        Section {
                            ForEach(amounts, id: \.self) { amount in
                                row(for: amount)
                            }
                        } header: {
                            Text("Tap an amount, then choose where it goes")
                        } footer: {
                            Text("This was read on your phone. The photo and these numbers are never uploaded.")
                        }
                    }
                }
            }
            .navigationTitle("Scanned amounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func row(for amount: Decimal) -> some View {
        HStack {
            Text(amount, format: .currency(code: "USD").precision(.fractionLength(amount.hasCents ? 2 : 0)))
                .font(Theme.Typography.money(.title3))
            if placed.contains(amount) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.statusColor(.okay))
                    .accessibilityLabel("Added")
            }
            Spacer()
            Menu {
                ForEach(ScanField.allCases) { field in
                    Button(field.rawValue) {
                        onAssign(field, NSDecimalNumber(decimal: amount).doubleValue)
                        withAnimation { _ = placed.insert(amount) }
                    }
                }
            } label: {
                Label("Add to…", systemImage: "plus.circle.fill")
                    .font(Theme.Typography.subheadline.weight(.semibold))
            }
            .accessibilityLabel("Add \(amount) to a field")
        }
        .frame(minHeight: Theme.minimumTapTarget)
    }
}

private extension Decimal {
    /// Whether the amount has a fractional part, so whole dollars show without
    /// a trailing ".00".
    var hasCents: Bool { self != self.rounded }
    var rounded: Decimal {
        var result = Decimal()
        var value = self
        NSDecimalRound(&result, &value, 0, .plain)
        return result
    }
}
