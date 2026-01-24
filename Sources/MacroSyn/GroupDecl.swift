//
//  GroupDecl.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 25/01/2026.
//

import SwiftSyntax

// MARK: - DeclGroupSyntax extensions

public extension SyntaxReader where Node: DeclGroupSyntax {
  var _properties: [Property] {
    node.memberBlock.members.flatMap { m in
      m.decl.as(VariableDeclSyntax.self).map { v in
        Variable.from(v)
      } ?? []
    }
  }

  var _functions: [Function] {
    node.memberBlock.members.compactMap { m in
      m.decl.as(FunctionDeclSyntax.self).map { Function($0) }
    }
  }

  var _initializers: [Initializer] {
    node.memberBlock.members.compactMap { m in
      m.decl.as(InitializerDeclSyntax.self).map { Initializer($0) }
    }
  }
}
