import SwiftUI
import PhotosUI

/// The sheet where a person enters their monthly numbers.
///
/// Plain words, one field each, whole dollars. Everything is optional — you can
/// fill in what you know and come back for the rest. Nothing is submitted
/// anywhere; "Save" writes to `MoneyPlanStore`, which keeps it on the device.
struct MyNumbersView: View {
    let store: MoneyPlanStore
    @Environment(\.dismiss) private var dismiss

    @State private var income: Double?
    @State private var housing: Double?
    @State private var homeUpkeep: Double?
    @State private var food: Double?
    @State private var energy: Double?
    @State private var transportation: Double?
    @State private var personal: Double?
    @State private var debt: Double?
    @State private var debtBalance: Double?
    @State private var debtAPR: Double?

    @State private var savedTrigger = 0
    @State private var showClearConfirm = false

    // Scan-a-bill flow (all on-device). See BillScanFlow.swift.
    @State private var showCamera = false
    @State private var photoItem: PhotosPickerItem?
    @State private var scannedAmounts: [Decimal] = []
    @State private var showScannedAmounts = false
    @State private var isReadingScan = false

    init(store: MoneyPlanStore) {
        self.store = store
        let plan = store.plan
        _income = State(initialValue: plan.monthlyIncome)
        _housing = State(initialValue: plan.housing)
        _homeUpkeep = State(initialValue: plan.homeUpkeep)
        _food = State(initialValue: plan.food)
        _energy = State(initialValue: plan.energy)
        _transportation = State(initialValue: plan.transportation)
        _personal = State(initialValue: plan.personal)
        _debt = State(initialValue: plan.debtPayments)
        _debtBalance = State(initialValue: plan.debtBalance)
        _debtAPR = State(initialValue: plan.debtAPR)
    }

    /// A labelled dollar field for one category, with its ⓘ "what to include".
    private func currencyField(_ kind: EssentialKind, _ binding: Binding<Double?>) -> some View {
        CurrencyField(title: kind.label, info: kind.info, value: binding)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    InfoTipRow()
                }
                .listRowBackground(Theme.brand.opacity(0.07))

                Section {
                    if DocumentScannerView.isCameraScanSupported {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Scan a bill with the camera", systemImage: "doc.viewfinder")
                        }
                    }
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Use a photo of a bill", systemImage: "photo")
                    }
                    if isReadingScan {
                        HStack(spacing: Theme.Spacing.tight) {
                            ProgressView()
                            Text("Reading the bill…")
                                .font(Theme.Typography.subheadline)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                } header: {
                    Text("Add faster")
                } footer: {
                    Text("Scan a bill and Headroom reads the amount for you — right here on your phone, nothing uploaded. You pick which field it fills.")
                }

                Section {
                    CurrencyField(title: "Money coming in", value: $income)
                } header: {
                    Text("Each month")
                } footer: {
                    Text("Your take-home pay — what actually lands in your account after tax.")
                }

                Section {
                    currencyField(.housing, $housing)
                    currencyField(.homeUpkeep, $homeUpkeep)
                } header: {
                    Text("Your home")
                } footer: {
                    Text("Rough amounts are fine — you can always come back and adjust.")
                }

                Section {
                    currencyField(.food, $food)
                    currencyField(.energy, $energy)
                    currencyField(.transportation, $transportation)
                    currencyField(.personal, $personal)
                } header: {
                    Text("Everyday costs")
                }

                Section {
                    currencyField(.debt, $debt)
                    CurrencyField(title: "Total you owe", value: $debtBalance)
                    HStack {
                        Text("Interest rate")
                            .font(Theme.Typography.body)
                        Spacer(minLength: Theme.Spacing.regular)
                        TextField("0", value: $debtAPR, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(Theme.Typography.money())
                            .frame(minWidth: 60)
                            .accessibilityLabel("Interest rate, annual percentage")
                        Text("% APR").foregroundStyle(Theme.secondaryText)
                    }
                    .frame(minHeight: Theme.minimumTapTarget)
                } header: {
                    Text("Debt")
                } footer: {
                    Text("Add the total you still owe and its rate to unlock “where debt clears soonest” — the places your balance could be gone fastest.")
                }

                Section {
                    Text("These numbers stay on this phone. They're never uploaded or shared.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.secondaryText)
                }

                if store.plan != .empty {
                    Section {
                        Button("Start over", role: .destructive) {
                            showClearConfirm = true
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    } footer: {
                        Text("Clears every number from this phone.")
                    }
                }
            }
            .navigationTitle("Your numbers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.save(MoneyPlan(
                            monthlyIncome: income,
                            housing: housing,
                            homeUpkeep: homeUpkeep,
                            food: food,
                            energy: energy,
                            transportation: transportation,
                            personal: personal,
                            debtPayments: debt,
                            debtBalance: debtBalance,
                            debtAPR: debtAPR
                        ))
                        savedTrigger += 1
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sensoryFeedback(.success, trigger: savedTrigger)
            .confirmationDialog("Clear all your numbers?", isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button("Clear everything", role: .destructive) {
                    store.clear()
                    dismiss()
                }
                Button("Keep them", role: .cancel) {}
            } message: {
                Text("This removes your income, essentials, and saved area from this phone. It can't be undone.")
            }
            .fullScreenCover(isPresented: $showCamera) {
                DocumentScannerView(
                    onScan: { images in
                        showCamera = false
                        readAmounts(from: images)
                    },
                    onCancel: { showCamera = false }
                )
                .ignoresSafeArea()
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        readAmounts(from: [image])
                    }
                    photoItem = nil
                }
            }
            .sheet(isPresented: $showScannedAmounts) {
                ScannedAmountsSheet(amounts: scannedAmounts) { field, value in
                    apply(field, value)
                }
            }
        }
    }

    /// Reads the images on-device, then shows what was found for the person to
    /// place. Never fills a field on its own.
    private func readAmounts(from images: [UIImage]) {
        isReadingScan = true
        Task {
            let text = await BillOCR.text(from: images)
            scannedAmounts = BillScanner.amounts(in: text)
            isReadingScan = false
            showScannedAmounts = true
        }
    }

    /// Drops a scanned amount into the field the person chose. Whole dollars, to
    /// match how the form is entered elsewhere.
    private func apply(_ field: ScanField, _ value: Double) {
        let dollars = value.rounded()
        switch field {
        case .income:         income = dollars
        case .housing:        housing = dollars
        case .homeUpkeep:     homeUpkeep = dollars
        case .food:           food = dollars
        case .energy:         energy = dollars
        case .transportation: transportation = dollars
        case .personal:       personal = dollars
        case .debt:           debt = dollars
        case .debtBalance:    debtBalance = dollars
        }
    }
}

/// A small, friendly hint that points at the ⓘ buttons — so a first-time user
/// knows those little icons explain what belongs in each grouped cost.
private struct InfoTipRow: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.regular) {
            ZStack {
                Circle()
                    .fill(Theme.brand.opacity(0.16))
                    .frame(width: 34, height: 34)
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.brand)
            }
            .accessibilityHidden(true)

            (Text("New here? Tap ")
             + Text(Image(systemName: "info.circle")).foregroundColor(Theme.brand)
             + Text(" beside any cost to see exactly what to include."))
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tip: tap the info button beside any cost to see what to include.")
    }
}

/// A right-aligned whole-dollar field with a leading "$".
///
/// Backed by a string so an empty field stays genuinely empty (not "0"), and
/// parsed to an optional `Double` so "blank" and "zero" stay distinct all the
/// way down to `MoneyPlan`.
struct CurrencyField: View {
    let title: String
    /// What to fold into this figure. When present, an ⓘ button shows it.
    var info: String? = nil
    @Binding var value: Double?

    @State private var text: String = ""
    @State private var showInfo = false

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Text(title)
                    .font(Theme.Typography.body)
                if let info {
                    Button {
                        showInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(Theme.brand)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("What counts as \(title)")
                    .popover(isPresented: $showInfo) {
                        Text(info)
                            .font(Theme.Typography.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding()
                            .frame(maxWidth: 300)
                            .presentationCompactAdaptation(.popover)
                    }
                }
            }
            Spacer(minLength: Theme.Spacing.regular)
            HStack(spacing: 2) {
                Text("$")
                    .foregroundStyle(Theme.secondaryText)
                TextField("0", text: $text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(Theme.Typography.money())
                    .frame(minWidth: 60)
                    .accessibilityLabel(title)
                    .accessibilityValue(value.map { "\(Int($0)) dollars" } ?? "empty")
            }
        }
        .frame(minHeight: Theme.minimumTapTarget)
        .onAppear {
            text = value.map { $0.formatted(.number.precision(.fractionLength(0)).grouping(.never)) } ?? ""
        }
        .onChange(of: text) { _, newValue in
            let cleaned = newValue.filter { $0.isNumber || $0 == "." }
            value = cleaned.isEmpty ? nil : Double(cleaned)
        }
        // Reflect a value set from outside the field — e.g. a scanned bill amount
        // dropped in here — without fighting the user's own typing (only refreshes
        // when the bound value and the shown text actually disagree).
        .onChange(of: value) { _, newValue in
            let shown = Double(text.filter { $0.isNumber || $0 == "." })
            if newValue != shown {
                text = newValue.map { $0.formatted(.number.precision(.fractionLength(0)).grouping(.never)) } ?? ""
            }
        }
    }
}

#if DEBUG
#Preview {
    MyNumbersView(store: .preview(.sampleTight))
}
#endif
