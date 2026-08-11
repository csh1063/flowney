import ComposableArchitecture
import Foundation
import Models
import SwiftData

/// 경로 검색 결과(`RouteLeg`)를 기기에 저장해서, 오프라인이거나 데이터를 아끼고 싶을 때
/// 서버(`route_cache`)까지도 안 가고 그대로 재사용한다. 서버 캐시와 동일하게 좌표(소수
/// 5자리 반올림) + 요청 수단("car"/"auto") 기준으로 키를 잡아서, 아이템이 재정렬되거나
/// 다른 여행의 동일 구간이어도 캐시가 그대로 재사용되고 좌표/수단이 바뀌면 자연히
/// 캐시 미스가 나서 별도 무효화 로직이 필요 없다. 서버(`day.js`)와 달리 만료(TTL) 없음 —
/// 여행 중 좌표는 안 바뀌니 계속 재사용 가능한 게 오프라인 목적에 더 맞는다.
@DependencyClient
public struct RouteCacheClient: Sendable {
    /// 하루치 아이템으로 인접 구간들을 만들고, 로컬에 캐시된(또는 좌표 없음/noRoute라 계산할
    /// 필요조차 없는) 구간은 즉시 채워서 돌려준다. `allCovered`가 true면 이 날짜는 네트워크를
    /// 태울 필요가 전혀 없다는 뜻.
    public var legsCoveringDay: @Sendable (_ items: [RouteLegRequestItem]) async -> (legs: [RouteLeg], allCovered: Bool) = { _ in ([], false) }
    /// 새로 받아온(또는 이미 캐시에 있던) 결과를 저장한다 — `OK` 상태인 leg만 저장한다(서버도
    /// 동일 — 실패한 탐색 결과는 캐싱하지 않고 다음에 다시 시도).
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

// MARK: - 조회/저장 로직 (서버 day.js의 resolveLeg/캐시 키 규칙과 동일하게 맞춤)

private enum RoutePairPlan {
    /// 좌표가 없거나 `noRoute`로 표시된 구간 — 서버도 계산 자체를 안 하므로 로컬에서 바로
    /// 합성하고 캐시 조회조차 하지 않는다.
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
            if let cached = await store.load(key: key) {
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

// MARK: - SwiftData

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
        // swiftlint:disable:next force_try
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
