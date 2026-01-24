//
//  ProtocolDecl.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 25/01/2026.
//

import SwiftSyntax

/// Reader for `protocol` declarations.
///
/// In addition to the standard declaration group members (properties, functions),
/// provides access to associated types and their constraints.
///
/// ```swift
/// let proto = ProtocolDecl(protocolDeclSyntax)
/// proto.associatedTypes[0].name          // "Element"
/// proto.associatedTypes[0].inheritedType // "Equatable"
/// ```
public struct ProtocolDecl: SyntaxReader {
  public let node: ProtocolDeclSyntax

  public init(_ node: ProtocolDeclSyntax) {
    self.node = node
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

  public var inheritedTypes: [String] {
    _inheritedTypes
  }

  public var associatedTypes: [AssociatedType] {
    node.memberBlock.members.compactMap { m in
      m.decl.as(AssociatedTypeDeclSyntax.self).map { AssociatedType($0) }
    }
  }
}

/// Reader for an `associatedtype` declaration within a protocol.
public struct AssociatedType: SyntaxReader {
  public let node: AssociatedTypeDeclSyntax

  public init(_ node: AssociatedTypeDeclSyntax) {
    self.node = node
  }

  public var name: String {
    node.name.text
  }

  /// The constraint type (e.g., "Equatable" in `associatedtype T: Equatable`)
  public var inheritedType: String? {
    _primaryInheritedType
  }

  /// All inherited types if there are multiple constraints
  public var inheritedTypes: [String] {
    _inheritedTypes
  }

  /// The default type (e.g., "Int" in `associatedtype T = Int`)
  public var defaultType: String? {
    node.initializer?.value.trimmedDescription
  }

  /// The where clause constraints
  public var whereClause: String? {
    node.genericWhereClause?.trimmedDescription
  }
}
