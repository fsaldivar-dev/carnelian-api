//
//  CarnelianClient.swift
//  Carnelian
//
//  The entry point. Wraps a `Firestore` instance and vends typed `Query`s.
//

import Foundation
import FirebaseFirestore

/// The Carnelian client: your door into Firebase persistence.
///
/// ```swift
/// let db = CarnelianClient()                      // default Firestore
/// let users = db.collection("users", of: User.self)
/// let all   = try await users.active().get()
/// ```
public final class CarnelianClient: @unchecked Sendable {

    /// The underlying Firestore handle. Inject one to point at a named database
    /// (e.g. the `test` / `stage` / `prod` databases resolved per environment).
    public let firestore: Firestore

    /// Create a client over an existing Firestore instance (the default one, or a
    /// named database configured at launch).
    public init(firestore: Firestore = .firestore()) {
        self.firestore = firestore
    }

    /// A typed handle to a top-level collection.
    public func collection<Element: CarnelianModel>(
        _ path: String,
        of type: Element.Type = Element.self
    ) -> Query<Element> {
        Query(collection: firestore.collection(path))
    }
}
