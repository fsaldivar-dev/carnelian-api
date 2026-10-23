//
//  AccountMerger.swift
//  CarnelianAuth
//
//  The extension point where the APP supplies its merge *policy*. CarnelianAuth
//  owns the Firebase flow; it never knows which collections or foreign keys an
//  app uses, so when two accounts must be merged it calls back into this.
//

public protocol AccountMerger: Sendable {
    /// Move everything owned by `orphanUID` to `baseUID`: reassign foreign keys
    /// (e.g. `userId` on records), inherit role/profile where the base is missing
    /// them, and soft-delete the orphan's user document.
    ///
    /// Important: deleting the orphan's **Firebase Auth** account is not possible
    /// from the client — only the Admin SDK on a backend can. This call migrates
    /// the data; schedule the auth-account deletion on your backend using the
    /// `orphanUID` reported by `LinkOutcome.merged`.
    func merge(from orphanUID: String, into baseUID: String) async throws
}
