//
//  CodeBlock.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 25/01/2026.
//

import SwiftSyntax

/// Reader for a single statement (declaration, expression, or statement) within a code block.
public struct Statement: SyntaxReader {
  public let node: CodeBlockItemSyntax

  public init(_ node: CodeBlockItemSyntax) {
    self.node = node
  }
}

/// Reader for a brace-delimited code block containing statements.
public struct CodeBlock: SyntaxReader {
  public let node: CodeBlockSyntax

  public init(_ node: CodeBlockSyntax) {
    self.node = node
  }
}
