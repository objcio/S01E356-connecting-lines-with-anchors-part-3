//

import SwiftUI

struct DirectionItem: Identifiable {
    var id = UUID()
    var icon: Image
    var text: String
}

let sample: [DirectionItem] = [
    .init(icon: Image(systemName: "location.circle.fill"), text: "My Location"),
    .init(icon: Image(systemName: "pin.circle.fill"), text: "Berlin Hauptbahnhof"),
    .init(icon: Image(systemName: "pin.circle.fill"), text: "Westend")
]

struct ContentView: View {
    var body: some View {
        DirectionList(items: sample)
        .padding()
    }
}

struct Connections {
    var frames: [DirectionItem.ID: Anchor<CGRect>] = [:]
    var connections: [(from: DirectionItem.ID, to: DirectionItem.ID)] = []

    mutating func merge(_ other: Connections) {
        frames.merge(other.frames, uniquingKeysWith: { $1 })
        connections.append(contentsOf: other.connections)
    }
}

struct ConnectionsKey: PreferenceKey {
    static let defaultValue = Connections()

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue())
    }
}

struct Line: Shape {
    var from: CGPoint
    var to: CGPoint

    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: from)
            p.addLine(to: to)
        }
    }
}

struct DottedLine: View {
    var availableHeight: CGFloat
    var diameter: CGFloat = 6
    var spacing: CGFloat = 6

    var body: some View {
        let numberOfCircles = floor((availableHeight + spacing) / (diameter+spacing))
        var boundingHeight = numberOfCircles * diameter + (numberOfCircles-1) * spacing
        Rectangle()
            .fill(.image(Image("dot")))
            .frame(height: boundingHeight)
    }
}

extension CGRect {
    subscript(unitPoint: UnitPoint) -> CGPoint {
        CGPoint(x: minX + width * unitPoint.x, y: minY + height * unitPoint.y)
    }
}

extension Collection {
    func withPrevious() -> [(item: Element, previous: Element?)] {
        guard let f = first else { return [] }
        return [(f, nil)] + Array(zip(self.dropFirst(), self))
    }
}

extension View {
    func connect(id: DirectionItem.ID, to previous: DirectionItem.ID?) -> some View {
        anchorPreference(key: ConnectionsKey.self, value: .bounds, transform: {
            Connections(frames: [id: $0], connections: previous.map { [(from: $0, to: id)] } ?? [])
        })
    }

    func drawConnections() -> some View {
        overlayPreferenceValue(ConnectionsKey.self) { connInfo in
            GeometryReader { proxy in
                let pairs = connInfo.connections
                ForEach(pairs, id: \.from) { (item, next) in
                    if let from = connInfo.frames[item], let to = connInfo.frames[next] {
                        let fromP = proxy[from][.bottom]
                        let toP = proxy[to][.top]
                        let availableHeight = toP.y-fromP.y
                        DottedLine(availableHeight: availableHeight-4)
                            .foregroundColor(.primary)
                            .frame(width: 6, height: availableHeight)
                            .offset(x: fromP.x - 3, y: fromP.y)
                    }
                }
            }
        }
    }
}

struct DirectionList: View {
    var items: [DirectionItem]

    var body: some View {
        List {
            ForEach(items.withPrevious(), id: \.item.id) { (item, previous) in
                HStack {
                    item.icon
                        .frame(width: 40)
                        .connect(id: item.id, to: previous?.id)

                    Text(item.text)
                    
                }
                .padding(.vertical, 17)
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
        .drawConnections()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .frame(width: 300)
    }
}
