import SwiftUI

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
    @State private var water: Double?
    @State private var transportation: Double?
    @State private var personal: Double?
    @State private var debt: Double?

    @State private var savedTrigger = 0
    @State private var showClearConfirm = false

    init(store: MoneyPlanStore) {
        self.store = store
        let plan = store.plan
        _income = State(initialValue: plan.monthlyIncome)
        _housing = State(initialValue: plan.housing)
        _homeUpkeep = State(initialValue: plan.homeUpkeep)
        _food = State(initialValue: plan.food)
        _energy = State(initialValue: plan.energy)
        _water = State(initialValue: plan.water)
        _transportation = State(initialValue: plan.transportation)
        _personal = State(initialValue: plan.personal)
        _debt = State(initialValue: plan.debtPayments)
    }

    /// A labelled dollar field for one category, with its ⓘ "what to include".
    private func currencyField(_ kind: EssentialKind, _ binding: Binding<Double?>) -> some View {
        CurrencyField(title: kind.label, info: kind.info, value: binding)
    }

    var body: some View {
        NavigationStack {
            Form {
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
                    Text("Tap the ⓘ next to any cost to see what to include in it. Rough amounts are fine.")
                }

                Section {
                    currencyField(.food, $food)
                    currencyField(.energy, $energy)
                    currencyField(.water, $water)
                    currencyField(.transportation, $transportation)
                    currencyField(.personal, $personal)
                } header: {
                    Text("Everyday costs")
                }

                Section {
                    currencyField(.debt, $debt)
                } header: {
                    Text("Debt")
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
                            water: water,
                            transportation: transportation,
                            personal: personal,
                            debtPayments: debt
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
        }
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
    }
}

#if DEBUG
#Preview {
    MyNumbersView(store: .preview(.sampleTight))
}
#endif
