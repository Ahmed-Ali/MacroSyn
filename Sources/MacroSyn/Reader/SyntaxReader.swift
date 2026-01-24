//
//  SyntaxReader.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 25/01/2026.
//

import SwiftSyntax

/// The root protocol for all MacroDSL reader types.
///
/// Conformers wrap a concrete SwiftSyntax node and expose ergonomic accessors.
/// Trait-based extensions on this protocol provide shared functionality
/// (access level, modifiers, generics, etc.) that concrete readers surface
/// through simple forwarding properties.
///
/// ```swift
/// let fn = Function(functionDeclSyntax)
/// fn.name       // from NamedDeclSyntax trait
/// fn.isAsync    // from WithSignature trait
/// ```
public protocol SyntaxReader<Node> {
  associatedtype Node: SyntaxProtocol
  var node: Node { get }
}

extension SyntaxReader where Node == AttributeSyntax {
  var name: String {
    node.attributeName.trimmedDescription
  }
}
