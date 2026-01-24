//
//  ActorDecl.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 25/01/2026.
//

import SwiftSyntax

/// Reader for `actor` declarations.
///
/// ```swift
/// let reader = ActorDecl(actorDeclSyntax)
/// reader.name          // "DataStore"
/// reader.properties    // [Property]
/// ```
public struct ActorDecl: SyntaxReader {
  public var node: ActorDeclSyntax

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
