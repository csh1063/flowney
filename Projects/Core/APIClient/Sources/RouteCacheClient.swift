import ComposableArchitecture
import Foundation
import Models
import SwiftData

@DependencyClient
public struct RouteCacheClient: Sendable {
    public var legsCoveringDay: @Sendable (_ items: [RouteLegRequestItem]) async -> (legs: [RouteLeg], allCovered: Bool) = { _ in ([], false) }
    public var save: @Sendable (_ legs: [RouteLeg], _ items: [RouteLegRequestItem]) async -> Void
}

extension RouteCacheClient: DependencyKey {
    public static let liveValue: RouteCacheClient = {
        let store = RouteCacheStore(modelContainer: RouteCacheContainer.shared)
        return RouteCacheClient(
            legsCoveringDay: { items in await computeLegsCoveringDay(items, store: store) },
            save: { legs, items in await persistLegs(legs, items: items, store: store) }
        )
    }()
}

extension DependencyValues {
    public var routeCacheClient: RouteCacheClient {
        get { self[RouteCacheClient.self] }
        set { self[RouteCacheClient.self] = newValue }
    }
}

private enum RoutePairPlan {
    case skipped(RouteLeg)
    case lookup(key: String)
}

private func plan(from: RouteLegRequestItem, to: RouteLegRequestItem) -> RoutePairPlan {
    guard
        !to.noRoute,
        let originLat = from.lat, let originLng = from.lng,
        let destLat = to.lat, let destLng = to.lng
    else {
        let mode = to.mode.flatMap(TransportMode.init(rawValue:)) ?? .walk
        return .skipped(RouteLeg(fromItemId: from.id, toItemId: to.id, mode: mode, status: .skipped))
    }
    let modeKey = to.mode == "car" ? "car" : "auto"
    return .lookup(key: cacheKey(originLat: originLat, originLng: originLng, destLat: destLat, destLng: destLng, mode: modeKey))
}

private func round5(_ value: Double) -> Double {
    (value * 100_000).rounded() / 100_000
}

private func cacheKey(originLat: Double, originLng: Double, destLat: Double, destLng: Double, mode: String) -> String {
    "\(round5(originLat))_\(round5(originLng))_\(round5(destLat))_\(round5(destLng))_\(mode)"
}

private func computeLegsCoveringDay(_ items: [RouteLegRequestItem], store: RouteCacheStore) async -> (legs: [RouteLeg], allCovered: Bool) {
    guard items.count >= 2 else { return ([], true) }
    var legs: [RouteLeg] = []
    var allCovered = true
    for index in 0 ..< (items.count - 1) {
        switch plan(from: items[index], to: items[index + 1]) {
        case let .skipped(leg):
            legs.append(leg)
        case let .lookup(key):
            if var cached = await store.load(key: key) {
                cached.fromItemId = items[index].id
                cached.toItemId = items[index + 1].id
                legs.append(cached)
            } else {
                allCovered = false
            }
        }
    }
    return (legs, allCovered)
}

private func persistLegs(_ legs: [RouteLeg], items: [RouteLegRequestItem], store: RouteCacheStore) async {
    let itemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
    for leg in legs where leg.status == .ok {
        guard
            let from = itemsByID[leg.fromItemId], let to = itemsByID[leg.toItemId],
            let originLat = from.lat, let originLng = from.lng,
            let destLat = to.lat, let destLng = to.lng
        else { continue }
        let modeKey = to.mode == "car" ? "car" : "auto"
        let key = cacheKey(originLat: originLat, originLng: originLng, destLat: destLat, destLng: destLng, mode: modeKey)
        await store.save(key: key, leg: leg)
    }
}

@Model
final class CachedRouteLegRecord {
    @Attribute(.unique) var key: String
    var legData: Data
    var createdAt: Date

    init(key: String, legData: Data, createdAt: Date = .now) {
        self.key = key
        self.legData = legData
        self.createdAt = createdAt
    }
}

enum RouteCacheContainer {
    static let shared: ModelContainer = {
        let schema = Schema([CachedRouteLegRecord.self])
        let configuration = ModelConfiguration(schema: schema)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
}

@ModelActor
actor RouteCacheStore {
    func load(key: String) -> RouteLeg? {
        let descriptor = FetchDescriptor<CachedRouteLegRecord>(predicate: #Predicate { $0.key == key })
        guard let record = try? modelContext.fetch(descriptor).first else { return nil }
        return try? JSONDecoder().decode(RouteLeg.self, from: record.legData)
    }

    func save(key: String, leg: RouteLeg) {
        guard let data = try? JSONEncoder().encode(leg) else { return }
        let descriptor = FetchDescriptor<CachedRouteLegRecord>(predicate: #Predicate { $0.key == key })
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.legData = data
            existing.createdAt = .now
        } else {
            modelContext.insert(CachedRouteLegRecord(key: key, legData: data))
        }
        try? modelContext.save()
    }
}
