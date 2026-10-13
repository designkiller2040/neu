import Foundation

enum Flow: String, Codable, CaseIterable, Identifiable {
    case light, medium, heavy
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum Symptom: String, Codable, CaseIterable, Identifiable {
    case cramps, headache, bloating, fatigue, backache, tenderness, acne, cravings, nausea
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum Mood: String, Codable, CaseIterable, Identifiable {
    case calm, happy, energetic, sensitive, anxious, low, irritable
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

struct DayLog: Codable, Equatable {
    var isPeriod = false
    var flow: Flow?
    var symptoms: Set<Symptom> = []
    var mood: Mood?
    var note = ""

    var isEmpty: Bool {
        !isPeriod && flow == nil && symptoms.isEmpty && mood == nil && note.isEmpty
    }
}

struct Period: Identifiable {
    var start: Date
    var end: Date
    var id: Date { start }
    var length: Int {
        (Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0) + 1
    }
}

struct CycleSummary: Identifiable {
    var start: Date
    var length: Int?        // nil while the cycle is still in progress
    var periodLength: Int
    var id: Date { start }
}

enum Phase {
    case menstrual, follicular, ovulation, luteal

    var name: String {
        switch self {
        case .menstrual: "Menstrual"
        case .follicular: "Follicular"
        case .ovulation: "Ovulation"
        case .luteal: "Luteal"
        }
    }

    var blurb: String {
        switch self {
        case .menstrual: "Rest and be gentle with yourself."
        case .follicular: "Energy is slowly rising."
        case .ovulation: "Peak energy, fertile window."
        case .luteal: "Winding down. Slow the pace."
        }
    }
}
