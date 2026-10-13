import Foundation
import Observation

@Observable
final class CycleStore {
    private(set) var logs: [String: DayLog] = [:]

    private let cal = Calendar.current
    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = dir.appendingPathComponent("cycle-logs.json")
        load()
    }

    // MARK: Logging

    func log(for date: Date) -> DayLog { logs[key(date)] ?? DayLog() }

    func update(_ date: Date, _ change: (inout DayLog) -> Void) {
        var entry = log(for: date)
        change(&entry)
        if !entry.isPeriod { entry.flow = nil }
        logs[key(date)] = entry.isEmpty ? nil : entry
        save()
    }

    func togglePeriod(on date: Date) {
        update(date) { $0.isPeriod.toggle() }
    }

    // MARK: Derived cycle data

    var periods: [Period] {
        let days = logs.filter { $0.value.isPeriod }.keys.compactMap(date(from:)).sorted()
        var result: [Period] = []
        for day in days {
            if var last = result.last, let gap = cal.dateComponents([.day], from: last.end, to: day).day, gap <= 1 {
                last.end = day
                result[result.count - 1] = last
            } else {
                result.append(Period(start: day, end: day))
            }
        }
        return result
    }

    var cycles: [CycleSummary] {
        let p = periods
        return p.indices.map { i in
            let length = i + 1 < p.count
                ? cal.dateComponents([.day], from: p[i].start, to: p[i + 1].start).day
                : nil
            return CycleSummary(start: p[i].start, length: length, periodLength: p[i].length)
        }
    }

    var averageCycleLength: Int {
        let lengths = cycles.compactMap(\.length).filter { (15...60).contains($0) }.suffix(6)
        guard !lengths.isEmpty else { return 28 }
        return Int((Double(lengths.reduce(0, +)) / Double(lengths.count)).rounded())
    }

    var averagePeriodLength: Int {
        let lengths = periods.map(\.length).suffix(6)
        guard !lengths.isEmpty else { return 5 }
        return max(1, Int((Double(lengths.reduce(0, +)) / Double(lengths.count)).rounded()))
    }

    var lastPeriodStart: Date? { periods.last?.start }

    var cycleDay: Int? {
        guard let start = lastPeriodStart else { return nil }
        let d = cal.dateComponents([.day], from: start, to: cal.startOfDay(for: .now)).day ?? 0
        return d >= 0 ? d + 1 : nil
    }

    var nextPeriodStart: Date? {
        lastPeriodStart.flatMap { cal.date(byAdding: .day, value: averageCycleLength, to: $0) }
    }

    /// Positive = days until, negative = days late.
    var daysUntilNextPeriod: Int? {
        guard let next = nextPeriodStart else { return nil }
        return cal.dateComponents([.day], from: cal.startOfDay(for: .now), to: next).day
    }

    var phase: Phase? {
        guard let day = cycleDay else { return nil }
        let ovulationDay = averageCycleLength - 14
        if day <= averagePeriodLength { return .menstrual }
        if abs(day - ovulationDay) <= 1 { return .ovulation }
        return day < ovulationDay ? .follicular : .luteal
    }

    // MARK: Predictions for the calendar

    func isPredictedPeriod(_ date: Date) -> Bool {
        guard let last = lastPeriodStart else { return false }
        let day = cal.startOfDay(for: date)
        guard day >= cal.startOfDay(for: .now), !log(for: day).isPeriod else { return false }
        let sinceLast = cal.dateComponents([.day], from: last, to: day).day ?? 0
        guard sinceLast >= averageCycleLength, sinceLast < averageCycleLength * 4 else { return false }
        return sinceLast % averageCycleLength < averagePeriodLength
    }

    func isPredictedOvulation(_ date: Date) -> Bool {
        guard let last = lastPeriodStart else { return false }
        let day = cal.startOfDay(for: date)
        guard day >= cal.startOfDay(for: .now) else { return false }
        let sinceLast = cal.dateComponents([.day], from: last, to: day).day ?? 0
        guard sinceLast >= 0, sinceLast < averageCycleLength * 4 else { return false }
        return sinceLast % averageCycleLength == averageCycleLength - 14 - 1
    }

    // MARK: Persistence

    private func key(_ date: Date) -> String {
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private func date(from key: String) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return cal.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: DayLog].self, from: data) else { return }
        logs = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(logs) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
