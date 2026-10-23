//
//  CarnelianError.swift
//  Carnelian
//

import Foundation

/// Errors surfaced by Carnelian operations.
public enum CarnelianError: Error, Equatable, Sendable {
    /// A document was requested by id but does not exist.
    case documentNotFound(id: String)
    /// A model was asked to be written/updated without an `id`.
    case missingDocumentID
    /// The underlying Firestore decode/encode failed.
    case decoding(String)
}
