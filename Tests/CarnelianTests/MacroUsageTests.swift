//
//  MacroUsageTests.swift
//  CarnelianTests
//
//  Integration test for the macro engine: this file only *compiles* if
//  @Repository and @Collection expand correctly. @Repository must inject the
//  `client` + `init`, and @Collection must synthesize the `members` getter.
//

import XCTest
import Carnelian

private struct Member: CarnelianModel {
    @Document var id: String?        // verifies the @Document -> DocumentID alias
    var name: String
    var isActive: Bool
}

@Repository
private actor MemberRepository {
    @Collection("members") var members: Query<Member>
}

final class MacroUsageTests: XCTestCase {

    // The @Repository actor + @Collection property above only *compile* if the
    // macros expand correctly (@Repository must inject `client` + `init`, and
    // @Collection must synthesize `get { client.collection("members") }`). We do
    // not instantiate the repository, so the test needs no configured FirebaseApp.
    func testMacrosExpandAndCompile() {
        _ = MemberRepository.self
    }
}
