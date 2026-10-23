//
//  CarnelianPlugin.swift
//  CarnelianMacros
//
//  The compiler plugin that backs @Repository and @Collection.
//
//  @Repository has two modes:
//
//   • On a concrete type (e.g. an `actor`): a MemberMacro that injects the
//     `CarnelianClient` + init, while @Collection (AccessorMacro) fills each
//     property's getter.
//
//   • On a `protocol`: a PeerMacro that generates a concrete `<Name>Live` struct
//     conforming to it, reading each requirement's @Collection path. Here
//     @Collection is just a marker (it emits no accessors inside a protocol).
//
//  Design note: @Collection only needs the collection *path*. The element type is
//  inferred by `CarnelianClient.collection(_:)` from the property's declared type
//  (`var users: Query<User>`), so the macro never parses generic arguments.
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

// MARK: - Shared parsing helpers

extension VariableDeclSyntax {
    /// The `@Collection(...)` attribute on this property, if present.
    var collectionAttribute: AttributeSyntax? {
        for attribute in attributes {
            if case let .attribute(attr) = attribute,
               attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "Collection" {
                return attr
            }
        }
        return nil
    }
}

extension AttributeSyntax {
    /// The string-literal path from `@Collection("path")`.
    var collectionPath: String? {
        guard
            let arguments = arguments?.as(LabeledExprListSyntax.self),
            let literal = arguments.first?.expression.as(StringLiteralExprSyntax.self)
        else { return nil }
        return literal.representedLiteralValue
    }
}

// MARK: - @Repository

/// `@Repository` — injects the client (concrete types) or generates a conforming
/// `<Name>Live` type (protocols).
public struct RepositoryMacro {}

/// Concrete-type mode: inject `client` + `init`.
extension RepositoryMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // On a protocol the conforming type is generated as a peer instead.
        if declaration.is(ProtocolDeclSyntax.self) { return [] }

        let client: DeclSyntax = "private let client: CarnelianClient"
        let initializer: DeclSyntax =
            """
            init(client: CarnelianClient = CarnelianClient()) {
                self.client = client
            }
            """
        return [client, initializer]
    }
}

/// Protocol mode: generate `<Name>Live` conforming to the protocol.
extension RepositoryMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let proto = declaration.as(ProtocolDeclSyntax.self) else {
            return []  // peer generation only applies to protocols
        }

        let protocolName = proto.name.text
        let liveName = protocolName + "Live"

        // Propagate the protocol's access level to the generated type, so a
        // `public protocol` yields a `public struct` with public members.
        let accessLevel = proto.modifiers.compactMap { modifier -> String? in
            switch modifier.name.tokenKind {
            case .keyword(.public): return "public"
            case .keyword(.package): return "package"
            case .keyword(.internal): return "internal"
            // A `private` protocol's witnesses must be at least `fileprivate`.
            case .keyword(.fileprivate), .keyword(.private): return "fileprivate"
            default: return nil
            }
        }.first
        let acl = accessLevel.map { "\($0) " } ?? ""

        var properties: [String] = []
        for member in proto.memberBlock.members {
            guard
                let variable = member.decl.as(VariableDeclSyntax.self),
                let attribute = variable.collectionAttribute,
                let path = attribute.collectionPath,
                let binding = variable.bindings.first,
                let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                let type = binding.typeAnnotation?.type
            else { continue }

            properties.append(
                #"\#(acl)var \#(name): \#(type.trimmedDescription) { client.collection("\#(path)") }"#
            )
        }

        let body = properties.joined(separator: "\n    ")
        let live: DeclSyntax =
            """
            \(raw: acl)struct \(raw: liveName): \(raw: protocolName) {
                private let client: CarnelianClient
                \(raw: acl)init(client: CarnelianClient = CarnelianClient()) {
                    self.client = client
                }
                \(raw: body)
            }
            """
        return [live]
    }
}

// MARK: - @Collection

/// `@Collection("path")` — on a concrete property, synthesizes
/// `get { client.collection("path") }`. On a protocol requirement it is a passive
/// marker (emits nothing) that `@Repository` reads.
public struct CollectionMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        // Inside a protocol, @Repository handles code generation.
        if context.lexicalContext.contains(where: { $0.is(ProtocolDeclSyntax.self) }) {
            return []
        }

        guard let path = node.collectionPath else {
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
