//
//  ClassDecl.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 25/01/2026.
//

import SwiftSyntax

/// Reader for `class` declarations.
///
/// ```swift
/// let reader = ClassDecl(classDeclSyntax)
/// reader.name          // "ViewModel"
/// reader.properties    // [Property]
/// reader.inheritedTypes // ["ObservableObject"]
/// ```
public struct ClassDecl: SyntaxReader {
  public let node: ClassDeclSyntax

  public init(_ node: ClassDeclSyntax) {
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
