//
//  CarnelianAuthError.swift
//  CarnelianAuth
//
//  Firebase Auth's NSError codes, mapped to a small, typed, Equatable enum.
//

import Foundation
import FirebaseAuth

public enum CarnelianAuthError: Error, Equatable, Sendable {
    /// No user is currently signed in, so there is nothing to link to.
    case notSignedIn
    /// This provider is already linked to the current account (no-op).
    case providerAlreadyLinked
    /// The email is already in use by another account.
    case emailAlreadyInUse
    /// The credential already belongs to **another** account — resolve with a
    /// merge (see `CarnelianAuth.resolveCollision(_:merging:)`).
    case credentialInUse
    /// Network failure.
    case network
    /// Anything else, with the Firebase message for context.
    case underlying(String)

    /// Map a Firebase Auth error to a `CarnelianAuthError`.
    public static func map(_ error: Error) -> CarnelianAuthError {
        let nsError = error as NSError
        guard nsError.domain == AuthErrorDomain,
              let code = AuthErrorCode(rawValue: nsError.code) else {
            return .underlying(nsError.localizedDescription)
        }
        switch code {
        case .providerAlreadyLinked:              return .providerAlreadyLinked
        case .credentialAlreadyInUse:             return .credentialInUse
        case .emailAlreadyInUse:                  return .emailAlreadyInUse
        case .accountExistsWithDifferentCredential: return .credentialInUse
        case .networkError:                       return .network
        default:                                  return .underlying(nsError.localizedDescription)
        }
    }
}
