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

    func testAddAssignsIDWhenMissing() async throws {
        let members = InMemoryCollection<Member>()
        let id = await members.add(Member(id: nil, name: "Ana", isActive: true))
        XCTAssertFalse(id.isEmpty)
        let stored = await members.get(id)
        XCTAssertEqual(stored?.name, "Ana")
    }

    func testSeedAndCount() async throws {
        let members = InMemoryCollection<Member>([
            Member(id: "1", name: "Ana", isActive: true),
            Member(id: "2", name: "Beto", isActive: true),
        ])
        let count = await members.count
        XCTAssertEqual(count, 2)
    }

    func testDeleteRemoves() async throws {
        let members = InMemoryCollection<Member>([Member(id: "1", name: "Ana", isActive: true)])
        await members.delete("1")
        let gone = await members.get("1")
        XCTAssertNil(gone)
    }
}
