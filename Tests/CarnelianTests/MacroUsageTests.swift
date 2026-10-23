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
    var id: String?
    var name: String
    var isActive: Bool
}

@Repository
private actor MemberRepository {
    @Collection("members") var members: Query<Member>
}

final class MacroUsageTests: XCTestCase {

    func testRepositoryGeneratesInitializerAndCollection() async {
        // `init()` comes from @Repository; `members` getter comes from @Collection.
        let repository = MemberRepository()
        let members = await repository.members
        _ = members
    }
}
