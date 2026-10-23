<div align="center">

![Carnelian — the fiery red jade for Firebase persistence](Assets/cover.webp)

# Carnelian

**The “fiery red jade” for Firebase persistence.**

*Declare your collections; Carnelian — the fiery jade — carves them onto Firebase.* 🔥

[![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20·%20macOS%20·%20tvOS%20·%20watchOS%20·%20visionOS-red.svg)](#)
[![License](https://img.shields.io/badge/license-MIT-black.svg)](LICENSE)

</div>

---

Carnelian is the sibling of [**JadeApi**](https://github.com/fsaldivar-dev/jade-api). Where
**Jade** declares your HTTP endpoints with annotations and runs them, **Carnelian** declares your
**Firestore** collections and carves out the repository that reads, writes, merges and soft-deletes
them — so each collection lives in one declarative place instead of hand-written boilerplate.

> 💚 **Jade** (green gem) → networking · ❤️ **Carnelian** (the fiery “red jade”) → Firebase

## Why

You end up writing the same `FirestoreMemberRepository` over and over: `data(as:)` to decode,
`setData(from:)` to write, `merge: true` to patch, a soft-delete convention, a server timestamp.
Carnelian turns that into a typed, declarative surface.

## Install

Swift Package Manager:

```swift
.package(url: "https://github.com/fsaldivar-dev/carnelian-api.git", from: "0.1.0")
```

Then add `Carnelian` (and `CarnelianTesting` to your test target).

## Usage

### Declarative (the goal — see Roadmap)

```swift
import Carnelian

struct User: CarnelianModel {
    @Document var id: String?
    var name: String
    var isActive: Bool
}

@Repository
protocol AppSchema {
    @Collection("users") var users: Query<User> { get }
    @Collection("posts") var posts: Query<Post> { get }
}
```

### Runtime (works today)

```swift
import Carnelian

let db = CarnelianClient()                       // default Firestore
let users = db.collection("users", of: User.self)

// Read (soft-delete aware, server-side count)
let active = try await users.active().order(by: "name").get()
let count  = try await users.count()

// Write
let id = try await users.add(User(id: nil, name: "Ana", isActive: true))
try await users.update(id, fields: ["name": "Ana María"])

// Delete (prefer soft delete)
try await users.softDelete(id)
```

### Testing without a network

```swift
import CarnelianTesting

let users = InMemoryCollection<User>([User(id: "1", name: "Ana", isActive: true)])
let all = await users.get()
```

## Design

- **One place per collection.** The annotation holds the path; the repository is generated.
- **Mirrors proven patterns.** CRUD, `merge: true`, soft-delete and `serverTimestamp()` match the
  hand-written repositories they replace.
- **Hand-mockable.** `CarnelianTesting` gives you an in-memory collection; no emulator required.
- **Release-safe.** Test helpers are a separate product, kept out of release builds.

## Roadmap

- [x] Runtime: `CarnelianClient`, typed `Query<Element>`, CRUD, soft-delete, count
- [x] `CarnelianTesting` in-memory collection
- [ ] **Macro engine** — expand `@Repository` / `@Collection` / `@Document` into the backing actor
- [ ] Named databases per environment (`test` / `stage` / `prod`)
- [ ] Listeners / snapshots (live queries)
- [ ] Batched writes & transactions

## License

[MIT](LICENSE) © Francisco Saldivar ([@fsaldivar-dev](https://github.com/fsaldivar-dev))
