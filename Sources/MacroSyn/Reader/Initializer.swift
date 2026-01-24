//
//  Initializer.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 24/01/2026.
//

import SwiftSyntax

/// Reader for initializer declarations.
///
/// ```swift
/// let initializer = Initializer(initDeclSyntax)
/// initializer.isFailable   // true for init?
/// initializer.parameters   // [Parameter]
/// ```
public struct Initializer: SyntaxReader {
  public let node: InitializerDeclSyntax

  public init(_ node: InitializerDeclSyntax) {
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

  /// Initializer-specific
  public var isFailable: Bool {
    node.optionalMark != nil
  }

  public var isImplicitlyUnwrapped: Bool {
    node.optionalMark?.tokenKind == .exclamationMark
  }
}
