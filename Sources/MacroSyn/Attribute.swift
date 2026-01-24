//
//  Attribute.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 25/01/2026.
//

import SwiftSyntax

/// Reader for a single attribute.
///
/// ```swift
/// let attr = reader.attributes[0]
/// attr.name      // "available"
/// attr.arguments // "*, deprecated"
/// ```
public struct Attribute: SyntaxReader {
  public let node: AttributeSyntax

  public init(_ node: AttributeSyntax) {
    self.node = node
  }

  public init?(_ node: AttributeListSyntax.Element) {
    switch node {
      case let .attribute(attributeSyntax):
        self.init(attributeSyntax)
      case .ifConfigDecl:
        return nil
    }
  }

  public var name: String {
    node.attributeName.trimmedDescription
  }

  public var arguments: String? {
    node.arguments?.trimmedDescription
  }
}

/// Reader for an attributed type (e.g. `@escaping (Int) -> Void`).
public struct AttributeType: SyntaxReader {
  public let node: AttributedTypeSyntax

  public init(_ node: AttributedTypeSyntax) {
    self.node = node
  }

  public var arguments: [Attribute]? {
    node.attributes.compactMap { Attribute($0) }
  }
}
