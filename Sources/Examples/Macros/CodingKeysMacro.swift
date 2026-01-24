//
//  CodingKeysMacro.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 13/02/2026.
//

import MacroSyn
import SwiftSyntax
import SwiftSyntaxMacros

/// `@CustomCodingKeys` — Generates a `CodingKeys` enum with snake_case raw values.
///
/// Given:
/// ```swift
/// @CustomCodingKeys
/// struct User {
///   let firstName: String
///   let lastName: String
///   let profileURL: String
/// }
/// ```
/// Generates:
/// ```swift
/// enum CodingKeys: String, CodingKey {
///   case firstName = "first_name"
///   case lastName = "last_name"
///   case profileURL = "profile_url"
/// }
/// ```
public struct CodingKeysMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf decl: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let syntax = decl.as(StructDeclSyntax.self) else { return [] }
    let structDecl = StructDecl(syntax)

    let storedProps = structDecl.properties.filter { !$0.isStatic }
    guard !storedProps.isEmpty else { return [] }

    let codingKeysEnum = try Enum("CodingKeys", inherits: ["String", "CodingKey"]) {
      for prop in storedProps {
        Case(prop.name, rawValue: "\"\(camelToSnakeCase(prop.name))\"")
      }
    }

    return [codingKeysEnum]
  }

  private static func camelToSnakeCase(_ input: String) -> String {
    var result = ""
    for (i, char) in input.enumerated() {
      if char.isUppercase {
        if i > 0 { result += "_" }
        result += char.lowercased()
      } else {
        result += String(char)
      }
    }
    return result
  }
}
