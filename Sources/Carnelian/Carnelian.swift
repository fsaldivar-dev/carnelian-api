//
//  Carnelian.swift
//  Carnelian — the fiery red jade for Firebase persistence.
//
//  Declare your collections with annotations; Carnelian carves them onto Firebase.
//
//  Carnelian is the sibling of JadeApi (networking). Where Jade declares HTTP
//  endpoints with annotations, Carnelian declares Firestore collections and
//  generates the repository that reads, writes, merges and soft-deletes them.
//

import FirebaseFirestore

// MARK: - @Repository / @Collection (macros)

/// Marks a type or protocol as a Carnelian repository. Two modes:
///
/// **On a concrete type** (preferably an `actor`): injects a `CarnelianClient`
/// and an initializer, so the type's `@Collection` properties have a client.
///
/// ```swift
/// @Repository
/// actor AppRepository {
///     @Collection("users") var users: Query<User>
/// }
/// let repo = AppRepository()                 // generated init
/// ```
///
/// **On a `protocol`**: generates a concrete `<Name>Live` struct that conforms to
/// it, implementing each `@Collection` requirement — the JadeApi-style model where
/// you declare the shape and the macro writes the implementation.
///
/// ```swift
/// @Repository
/// protocol AppRepository {
///     @Collection("users") var users: Query<User> { get }
/// }
/// // generates: struct AppRepositoryLive: AppRepository { ... }
/// let repo: AppRepository = AppRepositoryLive()
/// ```
@attached(member, names: arbitrary)
@attached(peer, names: suffixed(Live))
public macro Repository() =
    #externalMacro(module: "CarnelianMacros", type: "RepositoryMacro")

/// Binds a property to a Firestore collection path.
///
/// Expands `var users: Query<User>` into a computed property returning the typed
/// collection. The element type (`User`) is inferred from the property's type.
///
/// ```swift
/// @Collection("users") var users: Query<User>
/// ```
@attached(accessor)
public macro Collection(_ path: String) =
    #externalMacro(module: "CarnelianMacros", type: "CollectionMacro")

// MARK: - @Document

/// Marks the Firestore document identifier on a model.
///
/// This is Firestore's own `@DocumentID` property wrapper, re-exported under a
/// name that fits the Carnelian vocabulary. Firestore populates it with the
/// document id on decode and omits it from the written fields on encode.
///
/// ```swift
/// struct User: CarnelianModel {
///     @Document var id: String?
///     var name: String
/// }
/// ```
///
/// Note: if your toolchain does not resolve the alias form as a property wrapper,
/// use Firestore's `@DocumentID` directly — it is the identical type.
public typealias Document = DocumentID
