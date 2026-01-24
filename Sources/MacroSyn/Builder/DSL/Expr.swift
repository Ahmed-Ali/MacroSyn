//
//  Expr.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 25/01/2026.
//

import SwiftSyntax

// MARK: - Literal

/// Common literals for use in Return, Throw, etc.
/// Usage: `Return(.true)`, `Return(.nil)`, `Return(.int(42))`
public struct Literal: CustomStringConvertible, Sendable {
  public let description: String

  private init(_ description: String) {
    self.description = description
  }

  // Boolean
  public static let `true` = Literal("true")
  public static let `false` = Literal("false")

  /// Nil
  public static let `nil` = Literal("nil")

  /// Self
  public static let `self` = Literal("self")

  /// Numbers
  public static func int(_ value: Int) -> Literal {
    Literal(String(value))
  }

  public static let zero = Literal("0")
  public static let one = Literal("1")

  /// Strings
  public static func string(_ value: String) -> Literal {
    Literal("\"\(value)\"")
  }

  public static let emptyString = Literal("\"\"")

  // Collections
  public static let emptyArray = Literal("[]")
  public static let emptyDict = Literal("[:]")

  /// Custom expression
  public static func expr(_ expression: String) -> Literal {
    Literal(expression)
  }
}
