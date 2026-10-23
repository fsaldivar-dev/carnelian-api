//
//  InMemoryCollectionTests.swift
//  CarnelianTests
//
//  Runtime tests that need no network (they run against CarnelianTesting).
//

import XCTest
import Carnelian
@testable import CarnelianTesting

private struct Member: CarnelianModel {
    var id: String?
    var name: String
    var isActive: Bool
}

final class InMemoryCollectionTests: XCTestCase {

    func testAddAssignsIDWhenMissing() {
        let members = InMemoryCollection<Member>()
        let id = members.add(Member(id: nil, name: "Ana", isActive: true))
        XCTAssertFalse(id.isEmpty)
        XCTAssertEqual(members.get(id)?.name, "Ana")
    }

    func testSeedAndCount() {
        let members = InMemoryCollection<Member>([
            Member(id: "1", name: "Ana", isActive: true),
            Member(id: "2", name: "Beto", isActive: true),
        ])
        XCTAssertEqual(members.count, 2)
    }

    func testDeleteRemoves() {
        let members = InMemoryCollection<Member>([Member(id: "1", name: "Ana", isActive: true)])
        members.delete("1")
        XCTAssertNil(members.get("1"))
    }
}
