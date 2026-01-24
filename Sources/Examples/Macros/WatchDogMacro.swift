//
//  WatchDogMacro.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 24/01/2026.
//

import MacroSyn
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// `@Watch("prop1", "prop2")` — BodyMacro that wraps a function body
/// with print-based logging for the listed property names before and after the call.
///
/// Given:
/// ```swift
/// @Watch("count")
/// func increment() { count += 1 }
/// ```
/// Generates a body like:
/// ```swift
/// func increment() {
///   print("[WatchDog] count before = \(count)")
///   count += 1
///   print("[WatchDog] count after = \(count)")
/// }
/// ```
public struct WatchDogMacro: BodyMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
    in context: some MacroExpansionContext
  ) throws -> [CodeBlockItemSyntax] {
    // Extract watched property names from @Watch("prop1", "prop2", ...)
    guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
      return []
    }
    let watchedNames = arguments.compactMap {
      $0.expression.as(StringLiteralExprSyntax.self)?.segments.trimmedDescription
    }

    guard !watchedNames.isEmpty else { return [] }

    // Preserve the original body statements
    let originalStatements = declaration.body?.statements ?? []

    var items: [CodeBlockItemSyntax] = []

    // Before-logs
    for name in watchedNames {
      items.append(CodeBlockItemSyntax(stringLiteral:
        #"print("[WatchDog] \#(name) before = \(\#(name))")"#))
    }

    // Original body
    items.append(contentsOf: originalStatements)

    // After-logs
    for name in watchedNames {
      items.append(CodeBlockItemSyntax(stringLiteral:
        #"print("[WatchDog] \#(name) after = \(\#(name))")"#))
    }

    return items
  }
}
