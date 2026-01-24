//
//  Property.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 24/01/2026.
//

import SwiftSyntax

/// A property is a `Variable` viewed in the context of a type's member block.
/// Adds `stored` property to distinguish stored properties from computed ones.
public typealias Property = Variable

public extension Property {
  var stored: Bool {
    switch varSyntax.bindings.first?.accessorBlock?.accessors {
      case .none: return false

      case let .accessors(accessors):
        for a in accessors {
          if Set([.keyword(.set), .keyword(.didSet), .keyword(.willSet)]).contains(a.accessorSpecifier.tokenKind) {
            return true
          }
        }

        return false

      case .getter: return false
    }
  }
}
