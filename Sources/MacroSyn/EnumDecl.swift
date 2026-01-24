//
//  EnumDecl.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 24/01/2026.
//

import SwiftSyntax

/// Reader for `enum` declarations.
///
/// Provides access to cases (with raw values and associated values),
/// properties, functions, initializers, inheritance, and generic parameters.
///
/// ```swift
/// let reader = EnumDecl(enumDeclSyntax)
/// reader.cases[0].name                // "success"
/// reader.cases[0].associatedValues    // [AssociatedValue]
/// ```
public struct EnumDecl: SyntaxReader {
  public let node: EnumDeclSyntax

  public init(_ node: EnumDeclSyntax) {
    self.node = node
  }

  public init?(_ decl: DeclGroupSyntax) {
    guard let enumDecl = decl.as(EnumDeclSyntax.self) else {
      return nil
    }
    node = enumDecl
  }

  public var cases: [EnumCaseDecl] {
    node.memberBlock
      .members
      .compactMap {
        $0.decl.as(EnumCaseDeclSyntax.self)
      }
      .flatMap {
        EnumCaseDecl.from($0)
      }
  }

  public var accessLevel: AccessLevel? {
    _accessLevel
  }

  public var properties: [Property] {
    _properties
  }

  public var functions: [Function] {
    _functions
  }

  public var initializers: [Initializer] {
    _initializers
  }

  public var inheritedTypes: [String] {
    _inheritedTypes
  }

  public var hasGenericParameters: Bool {
    _hasGenericParameters
  }

  public var genericParameters: [GenericParameter] {
    _genericParameters
  }
}

/// Reader for a single enum case element.
///
/// A `case` declaration may list multiple cases (`case a, b, c`);
/// `EnumCaseDecl.from(_:)` splits them into individual entries.
public struct EnumCaseDecl: SyntaxReader {
  public let node: EnumCaseDeclSyntax
  public let caseDecl: EnumCaseElementSyntax

  public init(_ node: EnumCaseDeclSyntax, _ caseDecl: EnumCaseElementSyntax) {
    self.node = node
    self.caseDecl = caseDecl
  }

  public var name: String {
    caseDecl.name.text
  }

  public var rawValue: String? {
    caseDecl.rawValue?.value.trimmedDescription
  }

  public var hasAssociatedValues: Bool {
    caseDecl.parameterClause != nil
  }

  public var associatedValues: [AssociatedValue] {
    guard let clause = caseDecl.parameterClause else { return [] }
    return clause.parameters.map { AssociatedValue($0) }
  }

  static func from(_ decl: EnumCaseDeclSyntax) -> [Self] {
    decl.elements.map {
      EnumCaseDecl(decl, $0)
    }
  }
}

/// Reader for a single associated value parameter of an enum case.
public struct AssociatedValue: SyntaxReader {
  public let node: EnumCaseParameterSyntax

  public init(_ node: EnumCaseParameterSyntax) {
    self.node = node
  }

  public var label: String? {
    node.firstName?.text
  }

  public var type: String {
    node.type.trimmedDescription
  }

  public var defaultValue: String? {
    node.defaultValue?.value.trimmedDescription
  }
}
