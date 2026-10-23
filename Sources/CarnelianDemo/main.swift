//
//  main.swift
//  CarnelianDemo
//
//  A runnable walkthrough of Carnelian — run it with:
//
//      swift run CarnelianDemo
//
//  It needs no Firebase configuration: the CRUD session below runs against the
//  in-memory collection from CarnelianTesting, which shares the exact same shape
//  as the real `Query<User>` that talks to Firestore in production.
//

import Carnelian
import CarnelianTesting

// MARK: - 1. Your model

/// A plain Codable struct. `@Document` maps `id` to the Firestore document id.
struct User: CarnelianModel, CustomStringConvertible {
    @Document var id: String?
    var name: String
    var isActive: Bool

    var description: String { "User(id: \(id ?? "nil"), name: \(name), active: \(isActive))" }
}

// MARK: - 2. Your declarative schema
//
// This is the whole point of Carnelian. You write this…

@Repository
actor AppRepository {
    @Collection("users") var users: Query<User>
    @Collection("posts") var posts: Query<Post>
}

struct Post: CarnelianModel {
    @Document var id: String?
    var title: String
}

// …or declare a *protocol*, and @Repository generates a conforming `…Live` type:

@Repository
protocol GymRepository {
    @Collection("members") var members: Query<User> { get }
    @Collection("classes") var classes: Query<Post> { get }
}
// generated: struct GymRepositoryLive: GymRepository { client + init + both collections }

// In a real app you'd do (we don't call it here — it would hit live Firestore):
//
//     let repo: GymRepository = GymRepositoryLive()      // generated type
//     let active = try await repo.members.active().get()

func banner(_ title: String) {
    print("\n\u{001B}[1;31m● \(title)\u{001B}[0m")
}

print("""
\u{001B}[1;31m
   ▗▄▖  Carnelian — the fiery red jade for Firebase persistence
  ▐▙▟▌  Declare your collections; Carnelian carves them onto Firebase. 🔥
\u{001B}[0m
This demo runs the Carnelian API against an in-memory collection (no Firebase
needed). The same calls work on real Firestore via CarnelianClient.
""")

banner("You declared (protocol mode — the macro writes the implementation)")
print("""
    @Repository
    protocol GymRepository {
        @Collection("members") var members: Query<User>  { get }
        @Collection("classes") var classes: Query<Post>  { get }
    }
    // @Repository generates →  struct GymRepositoryLive: GymRepository { … }
""")

// MARK: - 3. A live CRUD session (in-memory, but same API surface)

let users = InMemoryCollection<User>()

banner("add — create documents (id auto-assigned when nil)")
let anaID = users.add(User(id: nil, name: "Ana", isActive: true))
let betoID = users.add(User(id: nil, name: "Beto", isActive: true))
print("  ➕ added Ana  → id \(anaID)")
print("  ➕ added Beto → id \(betoID)")

banner("count — how many documents")
print("  📊 count = \(users.count)")

banner("get(id) — read one")
if let ana = users.get(anaID) {
    print("  🔎 get(\(anaID)) → \(ana)")
}

banner("set — update a document")
if var ana = users.get(anaID) {
    ana.name = "Ana María"
    try users.set(ana)
    print("  ✏️  renamed → \(users.get(anaID)!)")
}

banner("get() — read all")
for user in users.get().sorted(by: { ($0.id ?? "") < ($1.id ?? "") }) {
    print("  • \(user)")
}

banner("delete — remove a document")
users.delete(betoID)
print("  🗑️  deleted Beto → count = \(users.count)")

banner("On real Firestore the same code reads/writes live")
print("""
    let db    = CarnelianClient()                 // default Firestore
    let users = db.collection("users", of: User.self)
    let active = try await users.active()          // isActive == true
                             .order(by: "name")
                             .get()                 // [User]
    try await users.softDelete(id)                 // flips isActive, keeps the row
""")

print("\n\u{001B}[1;31m✔ Demo complete — that's Carnelian. 🔴🔥\u{001B}[0m\n")
