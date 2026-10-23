//
//  CarnelianProvider.swift
//  CarnelianAuth
//
//  The sign-in providers Carnelian knows how to turn into a Firebase credential.
//  The app obtains the provider tokens (via Google Sign-In, Sign in with Apple,
//  a form, …) and hands them here; Carnelian builds the `AuthCredential`.
//

import FirebaseAuth

public enum CarnelianProvider: Sendable {
    case email(String, password: String)
    case google(idToken: String, accessToken: String)
    case apple(idToken: String, rawNonce: String)
    /// Escape hatch for any provider Carnelian does not model directly.
    case credential(AuthCredential)

    /// The Firebase credential for this provider.
    public var credential: AuthCredential {
        switch self {
        case let .email(email, password):
            return EmailAuthProvider.credential(withEmail: email, password: password)
        case let .google(idToken, accessToken):
            return GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        case let .apple(idToken, rawNonce):
            return OAuthProvider.appleCredential(
                withIDToken: idToken,
                rawNonce: rawNonce,
                fullName: nil
            )
        case let .credential(credential):
            return credential
        }
    }
}
