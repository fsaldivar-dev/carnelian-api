//
//  CarnelianModel.swift
//  Carnelian
//
//  The contract a type must satisfy to live in a Firestore collection.
//

import Foundation

/// A value that can be stored in and loaded from a Firestore document.
///
/// Conforming types are plain `Codable` structs. The `id` maps to the Firestore
/// document identifier (populate it with the `@Document` annotation, or leave it
/// `nil` and Carnelian assigns one on `add`).
///
/// Note: `CarnelianModel` deliberately does **not** require `Sendable`. Firestore's
/// `@DocumentID` property wrapper (what `@Document` maps to) is not `Sendable`, so
/// requiring it would make the headline id-mapping feature impossible to use.
public protocol CarnelianModel: Codable, Identifiable where ID == String? {
    var id: String? { get set }
}

/// Field names Carnelian writes automatically. Kept in one place so repositories
/// and the soft-delete convention stay consistent across the codebase.
public enum CarnelianField {
    public static let isActive = "isActive"
    public static let createdAt = "createdAt"
    public static let updatedAt = "updatedAt"
}
