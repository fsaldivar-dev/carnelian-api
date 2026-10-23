//
//  CarnelianPlugin.swift
//  CarnelianMacros
//
//  The compiler plugin that backs @Repository / @Collection / @Document.
//
//  STATUS: skeleton. The expansions below compile but do not yet emit code —
//  generating the Firestore-backed `actor` (CRUD, merge, soft-delete) from an
//  annotated protocol is the next milestone. The runtime API in `Carnelian`
//  (`CarnelianClient` / `Query`) is already fully usable without the macro.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

@main
struct CarnelianPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        RepositoryMacro.self,
        CollectionMacro.self,
        DocumentMacro.self,
    ]
}

/// Generates a Firestore-backed repository implementation for an annotated type.
public struct RepositoryMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // TODO: walk the @Collection members and synthesize the actor + CRUD.
        return []
    }
}

/// Binds a property to a Firestore collection path.
public struct CollectionMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // TODO: synthesize the backing `Query<Element>` accessor from the path.
        return []
    }
}

/// Marks the Firestore document identifier on a model.
public struct DocumentMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // TODO: bridge to Firestore's @DocumentID behavior.
        return []
    }
}
