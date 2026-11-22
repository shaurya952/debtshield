import SwiftUI
import Charts

/// The year ahead as a shape, not a sentence.
///
/// A single line would read as a prediction, which this is not — so the chart
/// draws the **middle** outcome with the quarter-to-three-quarters band around
/// it, and marks the zero line, because the question people actually have is
/// "do I run out, and roughly when".
///
/// Optionally overlays a second place, so someone can see what moving would do
/// to the same twelve months rather than reading two numbers and subtracting.
///
/// Colour is never the only signal: the median line is solid and the comparison
/// is dashed, the zero line is labelled, and the whole chart ships a spoken
/// summary for VoiceOver.
struct OutlookChartView: View {

    struct Series: Equatable {
        /// Running balance at the end of each month, month 1 … 12.
        let median: [Double]
        /// 25th and 75th percentile paths. Empty hides the band.
        var low: [Double] = []
        var high: [Double] = []
        /// What this line is — "Staying here", or a place name.
        let label: String
    }

    let here: Series
    /// A place being considered. Drawn dashed, above the band.
    var there: Series? = nil
    var height: CGFloat = 220

    private struct Point: Identifiable {
        let id = UUID()
        let month: Int
        let value: Double
        let series: String
    }

    private var herePoints: [Point] {
        here.median.enumerated().map { Point(month: $0.offset + 1, value: $0.element, series: here.label) }
    }

    private var therePoints: [Point] {
        guard let there else { return [] }
        return there.median.enumerated().map { Point(month: $0.offset + 1, value: $0.element, series: there.label) }
    }

    private var bandPoints: [(month: Int, low: Double, high: Double)] {
        guard here.low.count == here.median.count, here.high.count == here.median.count else { return [] }
        return here.median.indices.map { (month: $0 + 1, low: here.low[$0], high: here.high[$0]) }
    }

    /// Does the middle outcome ever go below zero, and when?
    private var firstNegativeMonth: Int? {
        here.median.firstIndex(where: { $0 < 0 }).map { $0 + 1 }
    }

    var body: some View {
        // Built from small pieces: as one expression the Swift Charts builder
        // blows the type-checker's budget.
        Chart {
            bandMarks
            zeroRule
            hereLine
            thereLine
        }
        .chartXAxis { xAxis }
        .chartYAxis { yAxis }
        .chartXScale(domain: 1...Double(MonteCarloEngine.horizonMonths))
        .padding(.trailing, Theme.Spacing.regular)
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your balance over the next year")
        .accessibilityValue(spokenSummary)
    }

    @ChartContentBuilder private var bandMarks: some ChartContent {
        ForEach(bandPoints, id: \.month) { p in
            AreaMark(x: .value("Month", p.month),
                     yStart: .value("Lower", p.low),
                     yEnd: .value("Upper", p.high))
                .foregroundStyle(Theme.brand.opacity(0.16))
                .interpolationMethod(.monotone)
        }
    }

    @ChartContentBuilder private var zeroRule: some ChartContent {
        RuleMark(y: .value("Zero", 0))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .foregroundStyle(Theme.secondaryText.opacity(0.55))
    }

    @ChartContentBuilder private var hereLine: some ChartContent {
        ForEach(herePoints) { p in
            LineMark(x: .value("Month", p.month),
                     y: .value("Balance", p.value),
                     series: .value("Series", p.series))
                .foregroundStyle(Theme.brand)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                .interpolationMethod(.monotone)
        }
    }

    @ChartContentBuilder private var thereLine: some ChartContent {
        ForEach(therePoints) { p in
            LineMark(x: .value("Month", p.month),
                     y: .value("Balance", p.value),
                     series: .value("Series", p.series))
                .foregroundStyle(Theme.accentWarm)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, dash: [7, 5]))
                .interpolationMethod(.monotone)
        }
    }

    @AxisContentBuilder private var xAxis: some AxisContent {
        AxisMarks(values: [1, 4, 8, 12]) { value in
            AxisGridLine().foregroundStyle(Theme.separator.opacity(0.4))
            AxisValueLabel {
                Text(value.as(Int.self) == 1 ? "Now" : "\(value.as(Int.self) ?? 0)mo")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    @AxisContentBuilder private var yAxis: some AxisContent {
        AxisMarks(position: .leading) { value in
            AxisGridLine().foregroundStyle(Theme.separator.opacity(0.4))
            AxisValueLabel {
                Text(PlaceFormat.money(value.as(Double.self) ?? 0))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    /// What a sighted reader takes from the shape, said out loud.
    private var spokenSummary: String {
        guard let last = here.median.last else { return "Not enough information yet." }
        var parts: [String] = []
        parts.append("\(here.label): about \(PlaceFormat.money(last)) after twelve months.")
        if let m = firstNegativeMonth {
            parts.append("The middle outcome drops below zero around month \(m).")
        } else {
            parts.append("The middle outcome stays above zero all year.")
        }
        if let there, let theirLast = there.median.last {
            let diff = theirLast - last
            let word = diff >= 0 ? "more" : "less"
            parts.append("\(there.label): about \(PlaceFormat.money(theirLast)), "
                         + "\(PlaceFormat.money(abs(diff))) \(word) after a year.")
        }
        return parts.joined(separator: " ")
    }
}

/// The key beneath the chart. Shape and label, never colour alone.
struct OutlookChartLegend: View {
    let hereLabel: String
    var thereLabel: String? = nil

    var body: some View {
        HStack(spacing: Theme.Spacing.comfortable) {
            item(color: Theme.brand, dashed: false, text: hereLabel)
            if let thereLabel {
                item(color: Theme.accentWarm, dashed: true, text: thereLabel)
            }
            Spacer(minLength: 0)
        }
        .accessibilityHidden(true)
    }

    private func item(color: Color, dashed: Bool, text: String) -> some View {
        HStack(spacing: 6) {
            Capsule()
                .strokeBorder(color, style: StrokeStyle(lineWidth: 3, dash: dashed ? [5, 4] : []))
                .frame(width: 26, height: 3)
            Text(text)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.secondaryText)
                .lineLimit(1)
        }
    }
}
