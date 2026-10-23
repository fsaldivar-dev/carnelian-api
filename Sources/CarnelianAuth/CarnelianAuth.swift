//
//  CarnelianAuth.swift
//  CarnelianAuth
//
//  Account linking over Firebase Auth. Carnelian owns the *flow*; your app owns
//  the *policy* (via AccountMerger). Mirrors Firebase's official model: linked
//  providers share one Firebase user ID.
//

import FirebaseAuth

/// The result of a link attempt.
public enum LinkOutcome: Equatable, Sendable {
    /// The provider was linked into the current account (one UID). The happy path.
    case linked(uid: String)
    /// The provider belonged to another account; its data was merged into the
    /// current one. `orphanUID`'s Firebase Auth account still needs deleting on
    /// your backend (the client cannot).
    case merged(keptUID: String, orphanUID: String)
}

public struct CarnelianAuth {

    private let auth: Auth

    public init(auth: Auth = Auth.auth()) {
        self.auth = auth
    }

    /// The provider IDs currently linked to the signed-in user
    /// (e.g. `["password", "google.com", "apple.com"]`).
    public var linkedProviders: [String] {
        auth.currentUser?.providerData.map(\.providerID) ?? []
    }

    /// Link a provider to the signed-in user (same UID — the Firebase model).
    ///
    /// On the happy path returns `.linked`. If the provider already belongs to a
    /// different account, throws `CarnelianAuthError.credentialInUse`; resolve it
    /// with `resolveCollision(_:merging:)`.
    @discardableResult
    public func link(_ provider: CarnelianProvider) async throws -> LinkOutcome {
        guard let user = auth.currentUser else { throw CarnelianAuthError.notSignedIn }
        do {
            let result = try await user.link(with: provider.credential)
            return .linked(uid: result.user.uid)
        } catch {
            throw CarnelianAuthError.map(error)
        }
    }

    /// Resolve a `credentialInUse` collision by merging the other account into the
    /// current one.
    ///
    /// Flow: capture the current (base) UID, sign in with the conflicting
    /// credential to learn the orphan's UID, then hand both UIDs to the app's
    /// `AccountMerger`. Pass the **same** provider you passed to `link(_:)`.
    ///
    /// Caveats (surfaced on purpose): signing in with the conflicting credential
    /// switches the active session to the orphan, so the merge runs under the
    /// orphan's identity — your Firestore rules or a backend may be required. And
    /// the orphan's Firebase Auth account can only be deleted by the Admin SDK.
    @discardableResult
    public func resolveCollision(
        _ provider: CarnelianProvider,
        merging merger: AccountMerger
    ) async throws -> LinkOutcome {
        guard let baseUID = auth.currentUser?.uid else { throw CarnelianAuthError.notSignedIn }
        do {
            let orphan = try await auth.signIn(with: provider.credential)
            let orphanUID = orphan.user.uid
            try await merger.merge(from: orphanUID, into: baseUID)
            return .merged(keptUID: baseUID, orphanUID: orphanUID)
        } catch let error as CarnelianAuthError {
            throw error
        } catch {
            throw CarnelianAuthError.map(error)
        }
    }

    /// Unlink a provider. Note: after unlinking, signing in with that provider
    /// again creates a **separate** account — it is not restored.
    public func unlink(_ providerID: String) async throws {
        guard let user = auth.currentUser else { throw CarnelianAuthError.notSignedIn }
        do {
            _ = try await user.unlink(fromProvider: providerID)
        } catch {
            throw CarnelianAuthError.map(error)
        }
    }
}
