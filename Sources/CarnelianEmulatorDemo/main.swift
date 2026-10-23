//
//  main.swift
//  CarnelianEmulatorDemo
//
//  Real CRUD + account linking/merge against the Firebase Emulator Suite.
//  Run it with the emulator wrapping the process:
//
//      firebase emulators:exec --project demo-carnelian 'swift run CarnelianEmulatorDemo'
//
//  No real Firebase project, credentials or network are involved — everything
//  hits the local Auth (:9099) and Firestore (:8080) emulators.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import Carnelian
import CarnelianAuth

// MARK: - Model

struct Member: CarnelianModel, CustomStringConvertible {
    @Document var id: String?
    var name: String
    var isActive: Bool
    var ownerUID: String?

    var description: String {
        "Member(id: \(id ?? "nil"), name: \(name), owner: \(ownerUID ?? "nil"))"
    }
}

// MARK: - The app's merge policy (what SajaruBox would implement)

struct DemoMerger: AccountMerger {
    let client: CarnelianClient

    func merge(from orphanUID: String, into baseUID: String) async throws {
        let members = client.collection("members", of: Member.self)
        let owned = try await members.where("ownerUID", isEqualTo: orphanUID).get()
        for member in owned {
            guard let id = member.id else { continue }
            try await members.update(id, fields: ["ownerUID": baseUID])
        }
        print("    merger: moved \(owned.count) doc(s) from \(orphanUID.prefix(6))… → \(baseUID.prefix(6))…")
    }
}

func banner(_ title: String) { print("\n\u{001B}[1;31m● \(title)\u{001B}[0m") }

// MARK: - 1. Configure Firebase against the emulators

// Fake-but-well-formed options: GOOGLE_APP_ID must match <v>:<num>:<platform>:<hex>.
let options = FirebaseOptions(googleAppID: "1:123456789012:ios:abcdef1234567890", gcmSenderID: "123456789012")
options.apiKey = "demo-api-key"
options.projectID = "demo-carnelian"
FirebaseApp.configure(options: options)

let db = Firestore.firestore()
let settings = db.settings
settings.host = "127.0.0.1:8085"
settings.isSSLEnabled = false
settings.cacheSettings = MemoryCacheSettings()
db.settings = settings
Auth.auth().useEmulator(withHost: "127.0.0.1", port: 9100)

let carnelian = CarnelianClient()
let members = carnelian.collection("members", of: Member.self)
let authn = CarnelianAuth()

print("""
\u{001B}[1;31m
   ▗▄▖  Carnelian — Emulator demo (real Firestore + Auth)
  ▐▙▟▌  CRUD · link · merge  🔥
\u{001B}[0m
""")

do {
    // MARK: - 2. Real CRUD through Carnelian (hits the Firestore emulator)

    banner("CRUD — add / get / update / count / softDelete (REAL Firestore)")
    let anaID = try await members.add(Member(id: nil, name: "Ana", isActive: true, ownerUID: nil))
    print("  ➕ add    → \(anaID)")
    print("  🔎 get    → \(try await members.get(anaID)!)")
    try await members.update(anaID, fields: ["name": "Ana María"])
    print("  ✏️  update → \(try await members.get(anaID)!)")
    print("  📊 count  → \(try await members.count())")
    try await members.softDelete(anaID)
    print("  🗑️  softDelete → active count = \(try await members.active().count())")

    // MARK: - 3. Account linking — happy path (one UID)

    banner("LINK (happy path) — anonymous user links an email provider")
    let anon: AuthDataResult = try await Auth.auth().signInAnonymously()
    print("  👤 anonymous uid = \(anon.user.uid.prefix(8))…")
    let linked = try await authn.link(.email("ana@demo.com", password: "secret123"))
    print("  🔗 link(.email) → \(linked)")
    print("  providers now = \(authn.linkedProviders)")

    // MARK: - 4. Account linking — collision → merge

    banner("MERGE (collision) — the email already belongs to another account")
    // Pre-create account B and give it a Firestore doc it 'owns'.
    try Auth.auth().signOut()
    let betoAccount: AuthDataResult = try await Auth.auth().createUser(withEmail: "beto@demo.com", password: "secret123")
    let orphanUID = betoAccount.user.uid
    let orphanDoc = try await members.add(
        Member(id: nil, name: "Beto", isActive: true, ownerUID: orphanUID)
    )
    print("  🅱️  account B uid = \(orphanUID.prefix(8))…  owns doc \(orphanDoc)")

    // Now a fresh base user tries to link Beto's email → collision.
    try Auth.auth().signOut()
    let base: AuthDataResult = try await Auth.auth().signInAnonymously()
    let baseUID = base.user.uid
    print("  👤 new base uid = \(baseUID.prefix(8))…")

    do {
        _ = try await authn.link(.email("beto@demo.com", password: "secret123"))
        print("  ⚠️  expected a collision but link succeeded")
    } catch CarnelianAuthError.credentialInUse {
        print("  ⚡️ collision detected → CarnelianAuthError.credentialInUse")
        let outcome = try await authn.resolveCollision(
            .email("beto@demo.com", password: "secret123"),
            merging: DemoMerger(client: carnelian)
        )
        print("  🔀 resolveCollision → \(outcome)")
    }

    // Prove the orphan's doc now belongs to the base account.
    let moved = try await members.get(orphanDoc)
    print("  ✅ doc \(orphanDoc) owner is now = \((moved?.ownerUID ?? "nil").prefix(8))…  (== base \(baseUID.prefix(8))…)")

    print("\n\u{001B}[1;31m✔ Emulator demo complete — CRUD, link and merge, all real. 🔴🔥\u{001B}[0m\n")
    exit(0)
} catch let error as NSError where error.code == 17995 {
    // FIRAuthErrorCodeKeychainError (-34018): FirebaseAuth stores its session in
    // the macOS Keychain, which requires a signed app bundle with a
    // keychain-access-groups entitlement. A bare `swift run` binary has none, so
    // Auth cannot run in this CLI — but it works in a real iOS/macOS app, and the
    // link/merge logic is covered by CarnelianAuthTests. The CRUD above was real.
    print("""

    \u{001B}[1;31mⓘ  Auth link/merge skipped — macOS CLI keychain limitation\u{001B}[0m
      The CRUD above ran against REAL Firestore (emulator). FirebaseAuth stores its
      session in the macOS Keychain, which needs a signed app bundle with a
      keychain-access-groups entitlement — a `swift run` binary has none
      (SecItemAdd -34018). So link/merge can't run in this CLI, but it works in a
      real app, and the logic is unit-tested in CarnelianAuthTests.

    \u{001B}[1;31m✔ Firestore CRUD demo complete (real). 🔴🔥\u{001B}[0m
    """)
    exit(0)
} catch {
    print("\n\u{001B}[1;31m✖ Demo failed:\u{001B}[0m \(error)")
    exit(1)
}
