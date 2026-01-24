//
//  StructDecl.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 25/01/2026.
//

import SwiftSyntax

/// Reader for `struct` declarations.
///
/// ```swift
/// let reader = StructDecl(structDeclSyntax)
/// reader.name          // "User"
/// reader.properties    // [Property]
/// reader.inheritedTypes // ["Codable"]
/// ```
public struct StructDecl: SyntaxReader {
  public let node: StructDeclSyntax

  public init(_ node: StructDeclSyntax) {
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
