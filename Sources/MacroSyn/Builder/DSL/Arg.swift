//
//  Arg.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 13/02/2026.
//

import SwiftSyntax
import SwiftSyntaxBuilder

// MARK: - ArgType Protocol

/// Marker protocol for types that can describe a Swift type name.
public protocol ArgType: Sendable {
  var typeName: String { get }
}

extension String: ArgType {
  public var typeName: String {
    self
  }
}

// MARK: - Arg

/// Describes a single function or initializer parameter.
///
/// ```swift
/// Arg("url", type: URL.self)
/// Arg("name", type: "String")
/// Arg("for", name: "value", type: Int.self)
/// ```
public struct Arg: Sendable {
  public let label: String
  public let name: String?
  public let typeName: String

  /// Create an argument with a string-based or custom ArgType conformer.
  public init(_ label: String, name: String? = nil, type: some ArgType) {
    self.label = label
    self.name = name
    typeName = type.typeName
  }

  /// Create an argument using a metatype: `Arg("url", type: URL.self)`.
  public init(_ label: String, name: String? = nil, type: Any.Type) {
    self.label = label
    self.name = name
    typeName = String(describing: type)
  }

  /// The rendered parameter string, e.g. `url: URL` or `for value: Int`.
  var parameterString: String {
    if let name {
      "\(label) \(name): \(typeName)"
    } else {
      "\(label): \(typeName)"
    }
  }
}
