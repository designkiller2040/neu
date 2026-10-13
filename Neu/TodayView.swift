import SwiftUI

struct TodayView: View {
    @Environment(CycleStore.self) private var store
    @State private var showLog = false

    private var today: Date { Calendar.current.startOfDay(for: .now) }
    private var isPeriodToday: Bool { store.log(for: today).isPeriod }

    var body: some View {
        ScrollView {
            VStack(spacing: 36) {
                header
                CycleRing(day: store.cycleDay, length: store.averageCycleLength)
                    .frame(width: 260, height: 260)
                    .padding(.top, 8)
                summary
                actions
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .screen()
        .sheet(isPresented: $showLog) {
            LogSheet(date: today)
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(today.formatted(.dateTime.weekday(.wide)))
                .font(Theme.caption).tracking(2).foregroundStyle(Theme.muted)
            Text(today.formatted(.dateTime.day().month(.wide)))
                .font(Theme.title(30))
        }
    }

    private var summary: some View {
        VStack(spacing: 8) {
            if let phase = store.phase {
                Text(phase.name).font(Theme.title(22))
                Text(phase.blurb).font(.subheadline).foregroundStyle(Theme.muted)
            } else {
                Text("Welcome").font(Theme.title(22))
                Text("Log the first day of your period to begin.")
                    .font(.subheadline).foregroundStyle(Theme.muted)
            }
            if let days = store.daysUntilNextPeriod {
                Text(nextPeriodText(days))
                    .font(.footnote).foregroundStyle(Theme.accent).padding(.top, 6)
            }
        }
        .multilineTextAlignment(.center)
    }

    private func nextPeriodText(_ days: Int) -> String {
        switch days {
        case 0: "Period expected today"
        case 1: "Period expected tomorrow"
        case ..<0: "Period \(-days) day\(days == -1 ? "" : "s") late"
        default: "Period in \(days) days"
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                store.togglePeriod(on: today)
            } label: {
                Text(isPeriodToday ? "Period ended" : "Period started")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accent, in: Capsule())
                    .foregroundStyle(.white)
            }
            Button {
                showLog = true
            } label: {
                Text("Log how you feel")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .overlay(Capsule().stroke(Theme.muted.opacity(0.4), lineWidth: 1))
            }
            .foregroundStyle(Theme.ink)
        }
    }
}

struct CycleRing: View {
    var day: Int?
    var length: Int

    private var progress: Double {
        guard let day else { return 0 }
        return min(Double(day) / Double(length), 1)
    }

    var body: some View {
        ZStack {
            Circle().stroke(Theme.surface, lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: progress)
            VStack(spacing: 2) {
                Text("DAY").font(Theme.caption).tracking(3).foregroundStyle(Theme.muted)
                Text(day.map(String.init) ?? "–")
                    .font(.system(size: 72, weight: .ultraLight, design: .serif))
            }
        }
    }
}
