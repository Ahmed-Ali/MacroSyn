//
//  MemberwiseInitMacro.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 13/02/2026.
//

import MacroSyn
import SwiftSyntax
import SwiftSyntaxMacros

/// `@MemberwiseInit` — Generates a public memberwise initializer for a struct.
///
/// Given:
/// ```swift
/// @MemberwiseInit
/// struct User {
///   let name: String
///   var age: Int
/// }
/// ```
/// Generates:
/// ```swift
/// public init(name: String, age: Int) {
///   self.name = name
///   self.age = age
/// }
/// ```
public struct MemberwiseInitMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf decl: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let syntax = decl.as(StructDeclSyntax.self) else { return [] }
    let structDecl = StructDecl(syntax)

    let properties = structDecl.properties.filter { !$0.isStatic && $0.type != nil }
    guard !properties.isEmpty else { return [] }

    let args = properties.map { prop in
      Arg(prop.name, type: prop.type!)
    }

    let initDecl = try Init(args, access: .public) {
      for prop in properties {
        CodeBlockItemSyntax(stringLiteral: "self.\(prop.name) = \(prop.name)")
      }
    }

    return [initDecl]
  }
}
