//
//  ProtocolRepositoryTests.swift
//  CarnelianTests
//
//  Integration test for @Repository's peer-type generation: @Repository on a
//  protocol must generate a concrete `<Name>Live` struct that conforms to it.
//  This file only *compiles* if that generated type exists and conforms.
//

import XCTest
import Carnelian

struct Athlete: CarnelianModel {
    var id: String?
    var name: String
    var isActive: Bool
}

@Repository
protocol GymSchema {
    @Collection("members") var members: Query<Athlete> { get }
    @Collection("coaches") var coaches: Query<Athlete> { get }
}

final class ProtocolRepositoryTests: XCTestCase {

    // Compiles only if `GymSchemaLive` was generated AND conforms to the protocol
    // (i.e. both @Collection requirements were implemented from their paths).
    private func requireConformance<T: GymSchema>(_ type: T.Type) {}

    func testProtocolGeneratesConformingLiveType() {
        requireConformance(GymSchemaLive.self)
    }
}
