//
//  Query.swift
//  Carnelian
//
//  A typed, chainable handle to a Firestore collection. This is the type the
//  `@Collection("users") var users: Query<User>` annotation ultimately vends.
//
//  Naming note: Firestore also ships a type called `Query`. Carnelian's `Query`
//  is generic (`Query<Element>`), so the two coexist; inside this module the
//  Firestore one is always written as `FirebaseFirestore.Query` to stay
//  unambiguous (see the SajaruBox collision guide).
//

import Foundation
import FirebaseFirestore

/// A typed view over a Firestore collection, plus a lightweight query builder.
///
/// CRUD mirrors the hand-written `FirestoreXRepository` patterns: `data(as:)`
/// for decoding, `setData(from:)` for writes, `merge: true` for partial updates,
/// and a soft-delete convention over hard deletes.
public struct Query<Element: CarnelianModel>: @unchecked Sendable {

    /// The collection this query is rooted at (used for document-level ops).
    internal let collection: CollectionReference
    /// The accumulated Firestore query (filters / order / limit).
    internal let base: FirebaseFirestore.Query

    internal init(collection: CollectionReference, base: FirebaseFirestore.Query? = nil) {
        self.collection = collection
        self.base = base ?? collection
    }

    // MARK: - Builder (returns a new Query; values are not mutated in place)

    public func `where`(_ field: String, isEqualTo value: Any) -> Query {
        Query(collection: collection, base: base.whereField(field, isEqualTo: value))
    }

    public func order(by field: String, descending: Bool = false) -> Query {
        Query(collection: collection, base: base.order(by: field, descending: descending))
    }

    public func limit(to count: Int) -> Query {
        Query(collection: collection, base: base.limit(to: count))
    }

    /// Convenience: only documents whose `isActive` is `true` (soft-delete aware).
    public func active() -> Query {
        self.where(CarnelianField.isActive, isEqualTo: true)
    }

    // MARK: - Read

    /// Fetch every document matching the current query.
    public func get() async throws -> [Element] {
        let snapshot = try await base.getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: Element.self) }
    }

    /// Fetch a single document by id, or `nil` when it does not exist.
    public func get(_ id: String) async throws -> Element? {
        let document = try await collection.document(id).getDocument()
        guard document.exists else { return nil }
        return try document.data(as: Element.self)
    }

    /// Count matching documents server-side, without downloading them.
    public func count() async throws -> Int {
        let snapshot = try await base.count.getAggregation(source: .server)
        return Int(truncating: snapshot.count)
    }

    // MARK: - Write

    /// Add a new document. If `model.id` is `nil`, Firestore assigns the id.
    /// Returns the document id that was written.
    @discardableResult
    public func add(_ model: Element) async throws -> String {
        if let id = model.id {
            try collection.document(id).setData(from: model)
            return id
        } else {
            let reference = collection.document()
            var copy = model
            copy.id = reference.documentID
            try reference.setData(from: copy)
            return reference.documentID
        }
    }

    /// Create or overwrite a document. `merge: true` only touches provided fields.
    public func set(_ model: Element, merge: Bool = true) async throws {
        guard let id = model.id else { throw CarnelianError.missingDocumentID }
        try collection.document(id).setData(from: model, merge: merge)
    }

    /// Update specific fields on a document (uses a server timestamp for `updatedAt`).
    public func update(_ id: String, fields: [String: Any]) async throws {
        var patch = fields
        patch[CarnelianField.updatedAt] = FieldValue.serverTimestamp()
        try await collection.document(id).updateData(patch)
    }

    // MARK: - Delete

    /// Soft delete (preferred): flips `isActive` to `false` and stamps `updatedAt`.
    public func softDelete(_ id: String) async throws {
        let document = try await collection.document(id).getDocument()
        guard document.exists else { throw CarnelianError.documentNotFound(id: id) }
        try await collection.document(id).updateData([
            CarnelianField.isActive: false,
            CarnelianField.updatedAt: FieldValue.serverTimestamp(),
        ])
    }

    /// Hard delete. Prefer `softDelete(_:)` unless you truly want the row gone.
    public func delete(_ id: String) async throws {
        try await collection.document(id).delete()
    }
}
