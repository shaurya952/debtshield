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
    @State private var food: Double?
    @State private var energy: Double?
    @State private var debt: Double?

    init(store: MoneyPlanStore) {
        self.store = store
        let plan = store.plan
        _income = State(initialValue: plan.monthlyIncome)
        _housing = State(initialValue: plan.housing)
        _food = State(initialValue: plan.food)
        _energy = State(initialValue: plan.energy)
        _debt = State(initialValue: plan.debtPayments)
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
                    CurrencyField(title: EssentialKind.housing.label, value: $housing)
                    CurrencyField(title: EssentialKind.food.label, value: $food)
                    CurrencyField(title: EssentialKind.energy.label, value: $energy)
                    CurrencyField(title: EssentialKind.debt.label, value: $debt)
                } header: {
                    Text("What goes out each month")
                } footer: {
                    Text("Rough amounts are fine. Debt payments means the least you must pay this month, not the total you owe.")
                }

                Section {
                    Text("These numbers stay on this phone. They're never uploaded or shared.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.secondaryText)
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
                            food: food,
                            energy: energy,
                            debtPayments: debt
                        ))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
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
    @Binding var value: Double?

    @State private var text: String = ""

    var body: some View {
        HStack {
            Text(title)
                .font(Theme.Typography.body)
            Spacer(minLength: Theme.Spacing.comfortable)
            HStack(spacing: 2) {
                Text("$")
                    .foregroundStyle(Theme.secondaryText)
                TextField("0", text: $text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(Theme.Typography.money())
                    .frame(minWidth: 60)
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
