//
//  CaseDetectionMacro.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 24/01/2026.
//

//  Created by Ahmed on 24/01/2026.

import MacroSyn
import SwiftSyntax
import SwiftSyntaxMacros

//  Example MemberMacro that generates `isCase` computed properties for each
//  case of an enum. Demonstrates the `EnumDecl` reader + `Var`, `If`, `Return` builders.

public struct CaseDetectionMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf decl: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let enumDecl = EnumDecl(decl) else { return [] }

    return try enumDecl.cases.map { enumCase in
      let upperCased = enumCase.name.prefix(1).uppercased() + enumCase.name.dropFirst()

      return try Var("is\(upperCased)", type: .bool) {
        try If("self == .\(enumCase.name)") {
          Return(.true)
        } else: {
          Return(.false)
        }
      }
    }
  }
}
