import SwiftUI

struct LogSheet: View {
    @Environment(CycleStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let date: Date

    var body: some View {
        let log = store.log(for: date)
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack {
                    Text(date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        .font(Theme.title(26))
                    Spacer()
                    Button("Done") { dismiss() }.foregroundStyle(Theme.accent)
                }

                Toggle("Period", isOn: Binding(
                    get: { log.isPeriod },
                    set: { on in store.update(date) { $0.isPeriod = on } }
                ))
                .tint(Theme.accent)

                if log.isPeriod {
                    section("Flow") {
                        FlowRow(items: Flow.allCases, selected: log.flow == nil ? [] : [log.flow!]) { f in
                            store.update(date) { $0.flow = $0.flow == f ? nil : f }
                        }
                    }
                }

                section("Mood") {
                    FlowRow(items: Mood.allCases, selected: log.mood.map { [$0] } ?? []) { m in
                        store.update(date) { $0.mood = $0.mood == m ? nil : m }
                    }
                }

                section("Symptoms") {
                    FlowRow(items: Symptom.allCases, selected: log.symptoms) { s in
                        store.update(date) {
                            if $0.symptoms.contains(s) { $0.symptoms.remove(s) } else { $0.symptoms.insert(s) }
                        }
                    }
                }

                section("Note") {
                    TextField("Anything else…", text: Binding(
                        get: { log.note },
                        set: { text in store.update(date) { $0.note = text } }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                    .padding(14)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(24)
        }
        .screen()
        .presentationDetents([.large])
    }

    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(Theme.caption).tracking(2).foregroundStyle(Theme.muted)
            content()
        }
    }
}

protocol Labeled: Identifiable, Hashable { var label: String { get } }
extension Flow: Labeled {}
extension Mood: Labeled {}
extension Symptom: Labeled {}

struct FlowRow<Item: Labeled>: View {
    let items: [Item]
    let selected: Set<Item>
    let tap: (Item) -> Void

    init(items: [Item], selected: some Collection<Item>, tap: @escaping (Item) -> Void) {
        self.items = items
        self.selected = Set(selected)
        self.tap = tap
    }

    var body: some View {
        WrapLayout(spacing: 8) {
            ForEach(items) { item in
                Button { tap(item) } label: {
                    Text(item.label).pill(selected: selected.contains(item))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Simple left-to-right wrapping layout for chips.
struct WrapLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(in: proposal.width ?? 320, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(in: bounds.width, subviews: subviews)
        for (i, origin) in result.origins.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(in width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, x - spacing)
        }
        return (CGSize(width: maxX, height: y + rowHeight), origins)
    }
}
