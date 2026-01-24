//
//  Function.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 24/01/2026.
//

import SwiftSyntax

/// Reader for function declarations.
///
/// Provides access to the function's name, return type, parameters,
/// access level, and effect specifiers (async/throws).
///
/// ```swift
/// let fn = Function(funcDeclSyntax)
/// fn.name        // "fetch"
/// fn.returnType  // "Data"
/// fn.isAsync     // true
/// fn.parameters  // [Parameter]
/// ```
public struct Function: SyntaxReader {
  public let node: FunctionDeclSyntax

  public init(_ node: FunctionDeclSyntax) {
    self.node = node
  }

  public var accessLevel: AccessLevel? {
    _accessLevel
  }

  public var parameters: [Parameter] {
    _parameters
  }

  public var isAsync: Bool {
    _isAsync
  }

  public var isThrowing: Bool {
    _isThrowing
  }

  public var throwingErrorType: String? {
    _throwingErrorType
  }

  /// Function-specific
  public var returnType: String? {
    node.signature.returnClause?.type.trimmedDescription
  }
}

import Foundation

/// Reader for a single function parameter.
///
/// Distinguishes between the external label (`firstName`), internal name
/// (`secondName`), and the effective `localName` used in the function body.
///
/// ```swift
/// // func greet(to name: String)
/// param.label     // "to"
/// param.secondName // "name"
/// param.localName  // "name"
/// ```
public struct Parameter: SyntaxReader {
  public let node: FunctionParameterSyntax

  public init(_ node: FunctionParameterSyntax) {
    self.node = node
  }

  /// The external parameter name (label), e.g., `for` in `func foo(for value: Int)`
  public var label: String {
    node.firstName.text
  }

  /// The internal parameter name, e.g., `value` in `func foo(for value: Int)`
  public var secondName: String? {
    node.secondName?.text
  }

  /// The effective name used in the function body
  public var localName: String {
    secondName ?? label
  }

  public var type: String {
    node.type.trimmedDescription
  }

  public var isInout: Bool {
    node.type.is(AttributedTypeSyntax.self) &&
      node.type.as(AttributedTypeSyntax.self)?.specifiers.contains {
        $0.as(SimpleTypeSpecifierSyntax.self)?.specifier.tokenKind == .keyword(.inout)
      } ?? false
  }

  public var defaultValue: String? {
    node.defaultValue?.value.trimmedDescription
  }

  public var isVariadic: Bool {
    node.ellipsis != nil
  }
}
