//
//  InMemoryCollection.swift
//  CarnelianTesting
//
//  A network-free, in-memory stand-in for a Carnelian collection — the mirror of
//  JadeApi's `MockClient`. Use it to exercise repository logic in tests without
//  touching Firestore. Excluded from release builds.
//
//  It is a plain `final class` (not an actor) so it can hold and return models
//  that are not `Sendable` — the norm for Firestore `@Document`-backed types.
//

import Foundation
import Carnelian

/// An in-memory collection with the same CRUD surface as `Query<Element>`.
public final class InMemoryCollection<Element: CarnelianModel> {

    private var storage: [String: Element] = [:]
    private var autoID = 0

    public init(_ seed: [Element] = []) {
        for model in seed {
            if let id = model.id { storage[id] = model }
        }
    }

    public func get() -> [Element] { Array(storage.values) }

    public func get(_ id: String) -> Element? { storage[id] }

    public var count: Int { storage.count }

    @discardableResult
    public func add(_ model: Element) -> String {
        if let id = model.id {
            storage[id] = model
            return id
        }
        autoID += 1
        let id = "mock-\(autoID)"
        var copy = model
        copy.id = id
        storage[id] = copy
        return id
    }

    public func set(_ model: Element) throws {
        guard let id = model.id else { throw CarnelianError.missingDocumentID }
        storage[id] = model
    }

    public func delete(_ id: String) { storage[id] = nil }
}
