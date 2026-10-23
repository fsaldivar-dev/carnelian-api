//
//  CarnelianAuthErrorTests.swift
//  CarnelianAuthTests
//
//  Pure tests for the error mapper (no FirebaseApp configuration needed).
//

import XCTest
import FirebaseAuth
@testable import CarnelianAuth

final class CarnelianAuthErrorTests: XCTestCase {

    private func authError(_ code: AuthErrorCode) -> NSError {
        NSError(domain: AuthErrorDomain, code: code.rawValue)
    }

    func testCredentialInUseMapsToCollision() {
        XCTAssertEqual(CarnelianAuthError.map(authError(.credentialAlreadyInUse)), .credentialInUse)
        XCTAssertEqual(CarnelianAuthError.map(authError(.accountExistsWithDifferentCredential)), .credentialInUse)
    }

    func testProviderAlreadyLinked() {
        XCTAssertEqual(CarnelianAuthError.map(authError(.providerAlreadyLinked)), .providerAlreadyLinked)
    }

    func testEmailInUseAndNetwork() {
        XCTAssertEqual(CarnelianAuthError.map(authError(.emailAlreadyInUse)), .emailAlreadyInUse)
        XCTAssertEqual(CarnelianAuthError.map(authError(.networkError)), .network)
    }

    func testNonAuthErrorFallsThrough() {
        let other = NSError(domain: "com.example.other", code: 42)
        if case .underlying = CarnelianAuthError.map(other) {
            // expected
        } else {
            XCTFail("expected .underlying for a non-Auth error")
        }
    }
}
