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

// MARK: - Annotations (macros)
//
// NOTE: The macro *engine* (code generation) is the next milestone — see
// `Sources/CarnelianMacros`. The declarations below define the intended surface
// shown on the README/cover. Until expansion lands you can use the runtime API
// (`CarnelianClient` / `Query`) directly, which is fully functional.

/// Marks a `protocol` (or schema type) as a Carnelian repository.
///
/// The macro generates a Firestore-backed `actor` implementation with CRUD,
/// `merge`, soft-delete and typed queries — the same shape you write by hand in
/// `FirestoreXRepository` today.
///
/// ```swift
/// @Repository
/// protocol MemberRepository {
///     @Collection("members") var members: Query<Member> { get }
/// }
/// ```
@attached(member, names: arbitrary)
public macro Repository() =
    #externalMacro(module: "CarnelianMacros", type: "RepositoryMacro")

/// Binds a property to a Firestore collection path.
///
/// ```swift
/// @Collection("users") var users: Query<User>
/// ```
@attached(peer)
public macro Collection(_ path: String) =
    #externalMacro(module: "CarnelianMacros", type: "CollectionMacro")

/// Marks the Firestore document identifier on a model.
///
/// ```swift
/// struct User: CarnelianModel {
///     @Document var id: String?
///     var name: String
/// }
/// ```
@attached(peer)
public macro Document() =
    #externalMacro(module: "CarnelianMacros", type: "DocumentMacro")
