import SwiftUI

struct HistoryView: View {
    @Environment(CycleStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("Cycles").font(Theme.title(30))

                HStack(spacing: 12) {
                    stat("\(store.averageCycleLength)", "Avg cycle, days")
                    stat("\(store.averagePeriodLength)", "Avg period, days")
                }

                if store.cycles.isEmpty {
                    Text("Your cycles will appear here once you log a period.")
                        .font(.subheadline).foregroundStyle(Theme.muted)
                } else {
                    VStack(spacing: 0) {
                        ForEach(store.cycles.reversed()) { cycle in
                            row(cycle)
                            Divider().overlay(Theme.surface)
                        }
                    }
                }
            }
            .padding(24)
        }
        .screen()
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value).font(.system(size: 44, weight: .ultraLight, design: .serif))
            Text(label).font(Theme.caption).foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))
    }

    private func row(_ cycle: CycleSummary) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(cycle.start.formatted(.dateTime.day().month(.wide).year()))
                    .font(.system(size: 17, weight: .light, design: .serif))
                Text("Period \(cycle.periodLength) days").font(.caption).foregroundStyle(Theme.muted)
            }
            Spacer()
            Text(cycle.length.map { "\($0) days" } ?? "In progress")
                .font(.subheadline)
                .foregroundStyle(cycle.length == nil ? Theme.accent : Theme.ink)
        }
        .padding(.vertical, 14)
    }
}
