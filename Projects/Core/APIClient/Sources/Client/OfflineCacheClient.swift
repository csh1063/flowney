import ComposableArchitecture
import Foundation
import SwiftData

@DependencyClient
public struct OfflineCacheClient: Sendable {
    public var load: @Sendable (_ key: String) async -> Data?
    public var save: @Sendable (_ key: String, _ data: Data) async -> Void
    public var keysWithPrefix: @Sendable (_ prefix: String) async -> [String] = { _ in [] }
    public var delete: @Sendable (_ key: String) async -> Void
}

extension OfflineCacheClient: DependencyKey {
    public static let liveValue: OfflineCacheClient = {
        let store = OfflineCacheStore(modelContainer: RouteCacheContainer.shared)
        return OfflineCacheClient(
            load: { key in await store.load(key: key) },
            save: { key, data in await store.save(key: key, data: data) },
            keysWithPrefix: { prefix in await store.allKeys(matching: prefix) },
            delete: { key in await store.delete(key: key) }
        )
    }()
}

extension OfflineCacheClient {
    public func loadCodable<T: Decodable>(_ type: T.Type, key: String) async -> T? {
        guard let data = await load(key), let value = try? JSONDecoder().decode(T.self, from: data) else { return nil }
        return value
    }

    public func saveCodable(_ value: some Encodable, key: String) async {
        guard let data = try? JSONEncoder().encode(value) else { return }
        await save(key, data)
    }
}

extension DependencyValues {
    public var offlineCacheClient: OfflineCacheClient {
        get { self[OfflineCacheClient.self] }
        set { self[OfflineCacheClient.self] = newValue }
    }
}

public enum OfflineCacheKey {
    public static let savedTrips = "offline:savedTrips"
    public static func trip(_ tripID: UUID) -> String { "offline:trip:\(tripID):meta" }
    public static func days(_ tripID: UUID) -> String { "offline:trip:\(tripID):days" }
    public static func items(_ tripID: UUID) -> String { "offline:trip:\(tripID):items" }
    public static func countries(_ tripID: UUID) -> String { "offline:trip:\(tripID):countries" }
    public static func budgetEntries(_ tripID: UUID) -> String { "offline:trip:\(tripID):budgetEntries" }
    public static func memoItems(_ tripID: UUID) -> String { "offline:trip:\(tripID):memoItems" }
    public static func weather(_ tripID: UUID) -> String { "offline:trip:\(tripID):weather" }
    public static func routeLegs(_ tripID: UUID) -> String { "offline:trip:\(tripID):routeLegs" }
}

@Model
final class CachedEntityRecord {
    @Attribute(.unique) var key: String
    var blobData: Data
    var updatedAt: Date

    init(key: String, blobData: Data, updatedAt: Date = .now) {
        self.key = key
        self.blobData = blobData
        self.updatedAt = updatedAt
    }
}

@ModelActor
actor OfflineCacheStore {
    func load(key: String) -> Data? {
        let descriptor = FetchDescriptor<CachedEntityRecord>(predicate: #Predicate { $0.key == key })
        return try? modelContext.fetch(descriptor).first?.blobData
    }

    func save(key: String, data: Data) {
        let descriptor = FetchDescriptor<CachedEntityRecord>(predicate: #Predicate { $0.key == key })
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.blobData = data
            existing.updatedAt = .now
        } else {
            modelContext.insert(CachedEntityRecord(key: key, blobData: data))
        }
        try? modelContext.save()
    }

    func allKeys(matching prefix: String) -> [String] {
        let descriptor = FetchDescriptor<CachedEntityRecord>()
        guard let records = try? modelContext.fetch(descriptor) else { return [] }
        return records.map(\.key).filter { $0.hasPrefix(prefix) }
    }

    func delete(key: String) {
        let descriptor = FetchDescriptor<CachedEntityRecord>(predicate: #Predicate { $0.key == key })
        guard let existing = try? modelContext.fetch(descriptor).first else { return }
        modelContext.delete(existing)
        try? modelContext.save()
    }
}
