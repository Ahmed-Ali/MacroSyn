//
//  Expressions.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 24/01/2026.
//

import SwiftSyntax

// MARK: - Literal Expressions

/// Protocol for expression readers that represent a literal value (string, int, bool, etc.).
public protocol LiteralExpr: SyntaxReader {
  associatedtype Value
  var type: String? { get }
  var value: Value { get }
}

public struct StringLiteral: LiteralExpr {
  public let node: StringLiteralExprSyntax
  public var type: String? {
    "String"
  }

  public var value: String {
    node.segments.compactMap { seg in
      if case let .stringSegment(s) = seg {
        s.content.text
      } else {
        ""
      }
    }.joined(separator: "")
  }
}

public struct LiteralIntExpr: LiteralExpr {
  public let node: IntegerLiteralExprSyntax
  public var type: String? {
    "Int"
  }

  public var value: String {
    node.literal.text
  }
}

public struct LiteralBoolExpr: LiteralExpr {
  public let node: BooleanLiteralExprSyntax
  public var type: String? {
    "Bool"
  }

  public var value: String {
    node.literal.text
  }
}

public struct LiteralNilExpr: LiteralExpr {
  public let node: NilLiteralExprSyntax
  public var type: String? {
    "Nil"
  }

  public var value: String? {
    nil
  }
}

public struct LiteralFloatExprReader: LiteralExpr {
  public let node: FloatLiteralExprSyntax
  public var type: String? {
    "Float"
  }

  public var value: String? {
    nil
  }
}

public struct LabeledExpr: SyntaxReader {
  public let node: LabeledExprSyntax

  public init(_ node: LabeledExprSyntax) {
    self.node = node
  }

  public var expression: ExprSyntax {
    node.expression
  }

  public var name: String? {
    node.label?.text
  }

  public var value: String {
    expression.trimmedDescription
  }
}

// MARK: Collection Expressions

public struct ArrayElement: SyntaxReader {
  public let node: ArrayElementSyntax

  public init(_ node: ArrayElementSyntax) {
    self.node = node
  }

  public var expression: ExprSyntax {
    node.expression
  }

  public var value: String {
    expression.trimmedDescription
  }
}

public struct ArrayExpr: SyntaxReader {
  public let node: ArrayExprSyntax

  public init(_ node: ArrayExprSyntax) {
    self.node = node
  }

  public var elements: [ArrayElement] {
    node.elements.map { ArrayElement($0) }
  }
}

public struct DictionaryElement: SyntaxReader {
  public let node: DictionaryElementSyntax

  public init(_ node: DictionaryElementSyntax) {
    self.node = node
  }

  public var key: String {
    node.key.trimmedDescription
  }

  public var value: String {
    node.value.trimmedDescription
  }
}

public struct DictionaryExpr: SyntaxReader {
  public let node: DictionaryExprSyntax

  public init(_ node: DictionaryExprSyntax) {
    self.node = node
  }

  public var elements: [DictionaryElement] {
    switch node.content {
      case .colon:
        []
      case let .elements(list):
        list.map { DictionaryElement($0) }
    }
  }

  public var asDictionary: [String: String] {
    var res: [String: String] = [:]
    for element in elements {
      res[element.key] = element.value
    }
    return res
  }
}
