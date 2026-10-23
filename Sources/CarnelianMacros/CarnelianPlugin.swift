//
//  CarnelianPlugin.swift
//  CarnelianMacros
//
//  The compiler plugin that backs @Repository and @Collection.
//
//  Design note: `@Collection` only needs to read the collection *path*. The
//  element type is inferred by `CarnelianClient.collection(_:)` from the
//  property's declared type (`var users: Query<User>` → `Query<User>`), so the
//  macro never has to parse generic arguments.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct CarnelianPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        RepositoryMacro.self,
        CollectionMacro.self,
    ]
}

/// Errors surfaced to the compiler as macro diagnostics.
enum CarnelianMacroError: Error, CustomStringConvertible {
    case message(String)
    var description: String {
        switch self {
        case .message(let text): return text
        }
    }
}

/// `@Repository` — injects the `CarnelianClient` and an initializer into the
/// annotated type, so its `@Collection` properties have a client to talk to.
///
/// Applied to an `actor`, the result is exactly the shape of the hand-written
/// `FirestoreXRepository`: an actor that vends typed, CRUD-capable collections.
///
/// The annotated type should hold only `@Collection` properties (the generated
/// initializer covers `client` only).
public struct RepositoryMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let client: DeclSyntax =
            "private let client: CarnelianClient"
        let initializer: DeclSyntax =
            """
            init(client: CarnelianClient = CarnelianClient()) {
                self.client = client
            }
            """
        return [client, initializer]
    }
}

/// `@Collection("path")` — turns a `var users: Query<User>` property into a
/// computed accessor that returns the typed collection from the client.
///
/// Expands to:
/// ```swift
/// get { client.collection("path") }
/// ```
public struct CollectionMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard
            let arguments = node.arguments?.as(LabeledExprListSyntax.self),
            let literal = arguments.first?.expression.as(StringLiteralExprSyntax.self),
            let path = literal.representedLiteralValue
        else {
            throw CarnelianMacroError.message(
                #"@Collection requires a string literal path, e.g. @Collection("users")"#
            )
        }

        let getter: AccessorDeclSyntax =
            """
            get { client.collection(\(literal: path)) }
            """
        return [getter]
    }
}
