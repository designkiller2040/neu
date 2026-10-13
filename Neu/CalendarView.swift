import SwiftUI

struct CalendarView: View {
    @Environment(CycleStore.self) private var store
    @State private var month = Calendar.current.startOfMonth(for: .now)
    @State private var selected: Date?

    private let cal = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(month.formatted(.dateTime.month(.wide).year())).font(Theme.title(24))
                Spacer()
                Button { shift(1) } label: { Image(systemName: "chevron.right") }
            }
            .foregroundStyle(Theme.ink)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, s in
                    Text(s).font(Theme.caption).foregroundStyle(Theme.muted)
                }
                ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                    if let date {
                        DayCell(date: date).onTapGesture { selected = date }
                    } else {
                        Color.clear.frame(height: 48)
                    }
                }
            }

            legend
            Spacer()
        }
        .padding(24)
        .screen()
        .sheet(item: Binding(get: { selected.map(Identified.init) }, set: { selected = $0?.date })) { item in
            LogSheet(date: item.date)
        }
    }

    private struct Identified: Identifiable {
        let date: Date
        var id: Date { date }
    }

    private var weekdaySymbols: [String] {
        let symbols = cal.veryShortStandaloneWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    private var days: [Date?] {
        let range = cal.range(of: .day, in: .month, for: month) ?? 1..<31
        let weekday = cal.component(.weekday, from: month)
        let offset = (weekday - cal.firstWeekday + 7) % 7
        let dates: [Date?] = range.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: month) }
        return Array(repeating: nil, count: offset) + dates
    }

    private func shift(_ by: Int) {
        month = cal.date(byAdding: .month, value: by, to: month) ?? month
    }

    private var legend: some View {
        HStack(spacing: 20) {
            legendItem(Circle().fill(Theme.accent), "Period")
            legendItem(Circle().stroke(Theme.accent, style: StrokeStyle(lineWidth: 1, dash: [2, 2])), "Expected")
            legendItem(Circle().fill(Theme.muted).frame(width: 4, height: 4), "Ovulation")
        }
        .font(.caption).foregroundStyle(Theme.muted)
    }

    private func legendItem<S: View>(_ shape: S, _ label: String) -> some View {
        HStack(spacing: 6) {
            shape.frame(width: 10, height: 10)
            Text(label)
        }
    }
}

struct DayCell: View {
    @Environment(CycleStore.self) private var store
    let date: Date

    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    var body: some View {
        let log = store.log(for: date)
        let period = log.isPeriod
        let predicted = store.isPredictedPeriod(date)
        ZStack {
            if period {
                Circle().fill(Theme.accent)
            } else if predicted {
                Circle().stroke(Theme.accent, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            } else if isToday {
                Circle().stroke(Theme.ink, lineWidth: 1)
            }
            VStack(spacing: 2) {
                Text(date.formatted(.dateTime.day()))
                    .font(.system(size: 16, weight: .light, design: .serif))
                    .foregroundStyle(period ? Color.white : Theme.ink)
                Circle()
                    .fill(dotColor(log: log, period: period))
                    .frame(width: 4, height: 4)
            }
        }
        .frame(height: 48)
        .contentShape(Rectangle())
    }

    private func dotColor(log: DayLog, period: Bool) -> Color {
        if store.isPredictedOvulation(date) { return Theme.muted }
        if !log.symptoms.isEmpty || log.mood != nil || !log.note.isEmpty {
            return period ? .white.opacity(0.8) : Theme.accent
        }
        return .clear
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
    }
}
