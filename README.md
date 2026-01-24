# MacroSyn

A Swift library that provides ergonomic wrappers around SwiftSyntax for both **reading** (parsing/inspecting) and **writing** (building/generating) Swift syntax in macro implementations.

MacroSyn eliminates the boilerplate of working with SwiftSyntax directly, letting you focus on your macro's logic rather than syntax tree navigation.

## Installation

Add MacroSyn as a dependency in your `Package.swift`:

```swift
.package(url: "https://github.com/Ahmed-Ali/MacroSyn.git", from: "0.0.1")
```

Then add it to your macro target:

```swift
.macro(
  name: "MyMacros",
  dependencies: ["MacroSyn"]
)
```

## Overview

MacroSyn has two sides:

| Side | Purpose | Key Types |
|------|---------|-----------|
| **Reader** | Parse and inspect existing Swift syntax | `StructDecl`, `EnumDecl`, `Function`, `Variable`, `Property` |
| **Builder** | Generate new Swift syntax | `Func()`, `Init()`, `Struct()`, `Enum()`, `If()`, `Switch()` |

Both sides are designed to work together — read declarations from user code, then generate new declarations using the builder DSL.

## Reader API

The Reader side wraps SwiftSyntax node types with ergonomic accessors. All reader types conform to the `SyntaxReader` protocol.

### Declaration Readers

```swift
// Wrap any DeclGroupSyntax node
let structDecl = StructDecl(node)   // wraps StructDeclSyntax
let classDecl  = ClassDecl(node)    // wraps ClassDeclSyntax
let enumDecl   = EnumDecl(node)     // wraps EnumDeclSyntax
let actorDecl  = ActorDecl(node)    // wraps ActorDeclSyntax
let protoDecl  = ProtocolDecl(node) // wraps ProtocolDeclSyntax
```

All declaration group readers share these properties:

```swift
structDecl.name              // "User"
structDecl.accessLevel       // .public, .private, etc.
structDecl.properties        // [Property] — all member variables
structDecl.functions         // [Function] — all member functions
structDecl.initializers      // [Initializer] — all init declarations
structDecl.inheritedTypes    // ["Codable", "Equatable"]
structDecl.genericParameters // [GenericParameter]
```

### Function & Parameter

```swift
let fn = Function(funcDeclSyntax)

fn.name            // "fetch"
fn.accessLevel     // .public
fn.returnType      // "Data"
fn.isAsync         // true
fn.isThrowing      // true
fn.throwingErrorType // "NetworkError" (typed throws)
fn.parameters      // [Parameter]

let param = fn.parameters[0]
param.label        // "for" (external name)
param.secondName   // "value" (internal name)
param.localName    // "value" (effective name in body)
param.type         // "Int"
param.isInout      // false
param.isVariadic   // false
param.defaultValue // nil
```

### Initializer

```swift
let initializer = Initializer(initDeclSyntax)

initializer.accessLevel  // .public
initializer.parameters   // [Parameter]
initializer.isFailable   // true (init?)
initializer.isImplicitlyUnwrapped // true (init!)
initializer.isAsync      // false
initializer.isThrowing   // false
```

### Variable & Property

```swift
let variables = Variable.from(variableDeclSyntax)

let v = variables[0]
v.name           // "count"
v.type           // "Int"
v.value          // "0" (initializer value)
v.mutable        // true (var with setter)
v.isLet          // false
v.isVar          // true
v.accessLevel    // .public
v.setterAccessLevel // .private (for `public private(set) var`)
v.isStatic       // false
v.isLazy         // false
v.isWeak         // false
```

`Property` is a typealias for `Variable` with an additional `stored` property.

### Enum Cases

```swift
let enumDecl = EnumDecl(enumDeclSyntax)

for c in enumDecl.cases {
  c.name              // "success"
  c.rawValue          // "\"ok\"" (if raw-value enum)
  c.hasAssociatedValues // true
  c.associatedValues  // [AssociatedValue]

  for av in c.associatedValues {
    av.label         // "value" (nil if unlabeled)
    av.type          // "Int"
    av.defaultValue  // nil
  }
}
```

### Protocol Declarations

```swift
let proto = ProtocolDecl(protocolDeclSyntax)

proto.associatedTypes  // [AssociatedType]

let at = proto.associatedTypes[0]
at.name           // "Element"
at.inheritedType  // "Equatable"
at.defaultType    // "Int"
at.whereClause    // "where Element: Comparable"
```

### Modifier Traits

All readers on types conforming to `WithModifiersSyntax` expose:

```swift
reader.isStatic        reader.isClass
reader.isFinal         reader.isLazy
reader.isWeak          reader.isUnowned
reader.isMutating      reader.isNonmutating
reader.isOptional      reader.isNonisolated
reader.isOverride      reader.isRequired
reader.isConvenience   reader.isDynamic
reader.isIndirect      reader.isDistributed
reader.isConsuming     reader.isBorrowing
```

### Attributes

```swift
let attrs = reader.attributes  // [Attribute]
attrs[0].name       // "available"
attrs[0].arguments  // "*, deprecated"
```

### Generic Parameters

```swift
reader.hasGenericParameters  // true
reader.genericParameters     // [GenericParameter]

let gp = reader.genericParameters[0]
gp.name           // "T"
gp.inheritedType  // "Equatable"
gp.isParameterPack // true (for `each T`)
```

### Diagnostics

Every reader type can create diagnostics with an ergonomic builder:

```swift
// Simple error
let diag = variable.error("Must be mutable").build()

// Error on a specific token with fix-it
let diag = variable
  .error("Expected 'var'", on: variable.bindingKeyword)
  .fix("Change to 'var'", replace: variable.bindingKeyword, with: .var)
  .build()

// Warning
let diag = function.warning("Consider making this async").build()

// Emit in macro context
context.diagnose(diag)
```

### Syntax Interpolation

Reader types can be interpolated directly into SwiftSyntax string interpolations:

```swift
// Property interpolates as its name
DeclSyntax("case \(prop)")  // -> "case myProperty"

// AccessLevel interpolates as keyword + space
FunctionDeclSyntax("\(fn.accessLevel)func wrapper()")  // -> "public func wrapper()"

// Parameter interpolates as its local name
ExprSyntax("\(param)")  // -> "value"

// EnumCaseDecl interpolates as its name
ExprSyntax(".\(enumCase)")  // -> ".success"
```

## Builder API

The Builder side provides Swift functions that generate SwiftSyntax nodes. All builder functions are free functions with capitalized names mirroring Swift keywords.

### TypeRef — Type References

```swift
// Built-in type constants
TypeRef.bool, .int, .double, .float, .string, .void, .any
TypeRef.data, .date, .url, .error

// Constructors
TypeRef.custom("MyModel")
TypeRef.array(of: .int)           // [Int]
TypeRef.dict(key: .string, value: .int) // [String: Int]
TypeRef.optional(.string)         // String?
TypeRef.result(success: .data)    // Result<Data, Error>
```

### Literal — Value Literals

```swift
Literal.true, .false, .nil, .self
Literal.zero, .one, .int(42)
Literal.emptyString, .string("hello")
Literal.emptyArray, .emptyDict
Literal.expr("someExpression()")
```

### Arg — Function/Init Parameters

```swift
// String type name
Arg("name", type: "String")

// Metatype (Any.Type)
Arg("url", type: URL.self)

// External + internal name
Arg("for", name: "value", type: Int.self)
```

`ArgType` is a marker protocol for extensibility — `String` conforms out of the box.

### Func — Function Declarations

The `Func()` function returns a `FuncBuilder` that you terminate with `.returns(type) { body }` or `.body { ... }`:

```swift
// Function with return type
try Func("fetch", Arg("url", type: URL.self), async: true, throws: true)
  .returns(.data) {
    Return(expr: "try await URLSession.shared.data(from: url)")
  }

// Void function
try Func("configure", Arg("name", type: String.self))
  .body {
    "self.name = name"
  }

// Static, public function
try Func("create", access: .public, static: true)
  .returns(.custom("Self")) {
    Return(expr: "Self()")
  }
```

### Init — Initializer Declarations

```swift
try Init(Arg("name", type: String.self), Arg("age", type: Int.self), access: .public) {
  "self.name = name"
  "self.age = age"
}

// Failable initializer
try Init(Arg("value", type: Int.self), failable: true) {
  try Guard("value > 0", otherwise: { Return(.nil) })
  "self.value = value"
}

// Array overload for programmatic use
let args = properties.map { Arg($0.name, type: $0.type!) }
try Init(args, access: .public) { ... }
```

### StoredVar — Stored Properties

```swift
StoredVar("count", type: .int, value: .zero)
StoredVar("name", type: .string, isLet: true, access: .public)
```

### Var — Computed Properties

```swift
try Var("isValid", type: .bool) {
  Return(.true)
}

try Var("description", type: .string, access: .public) {
  Return(expr: "\"\\(name): \\(age)\"")
}
```

### Type Declarations

#### Struct

```swift
try Struct("User", access: .public, inherits: ["Codable", "Equatable"]) {
  StoredVar("name", type: .string)
  StoredVar("age", type: .int)
}
```

#### Class

```swift
try Class("ViewModel", access: .public, inherits: ["ObservableObject"]) {
  StoredVar("title", type: .string, value: .emptyString)
}
```

#### Enum

```swift
try Enum("Direction", inherits: ["String"]) {
  Case("north")
  Case("south", rawValue: "\"S\"")
  Case("error", args: (nil, "String"), ("code", "Int"))
}
```

#### Extension

```swift
try Extension("User", conformingTo: ["CustomStringConvertible"]) {
  try Var("description", type: .string) {
    Return(expr: "name")
  }
}
```

### Statement Builders

#### If / Else

```swift
try If("condition") {
  Return(.true)
} else: {
  Return(.false)
}
```

#### Guard

```swift
try Guard("let value = optional", otherwise: {
  Return(.nil)
})
```

#### Switch / Case

```swift
try Switch("direction") {
  try SwitchCase("case .north:") {
    Return(expr: "\"up\"")
  }
  try SwitchCase("default:") {
    Return(expr: "\"unknown\"")
  }
}
```

#### For / While

```swift
try For("item", in: "items") {
  "process(item)"
}

try While("condition") {
  "doWork()"
}
```

#### Do / Catch

```swift
try Do {
  "try riskyOperation()"
} catch: {
  try Catch("let error as NetworkError") {
    "handleNetwork(error)"
  }
  try Catch {
    "print(error)"
  }
}
```

#### Return / Throw

```swift
Return(.true)
Return(expr: "value + 1")
Return()
Throw("MyError.invalid")
```

## Full Example: Writing a Macro

Here's a complete macro that generates a memberwise initializer using both the Reader and Builder APIs:

```swift
import MacroSyn
import SwiftSyntax
import SwiftSyntaxMacros

public struct MemberwiseInitMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf decl: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    // Reader side: inspect the struct
    guard let syntax = decl.as(StructDeclSyntax.self) else { return [] }
    let structDecl = StructDecl(syntax)

    let properties = structDecl.properties.filter { !$0.isStatic && $0.type != nil }
    guard !properties.isEmpty else { return [] }

    // Builder side: generate the init
    let args = properties.map { Arg($0.name, type: $0.type!) }

    let initDecl = try Init(args, access: .public) {
      for prop in properties {
        CodeBlockItemSyntax(stringLiteral: "self.\(prop.name) = \(prop.name)")
      }
    }

    return [initDecl]
  }
}
```

Applied to:

```swift
@MemberwiseInit
struct User {
  let name: String
  var age: Int
}
```

Generates:

```swift
public init(name: String, age: Int) {
  self.name = name
  self.age = age
}
```

## More Examples

The `Sources/Examples/` directory contains working macro implementations:

| Macro | Type | Demonstrates |
|-------|------|-------------|
| `@CaseDetection` | MemberMacro | `EnumDecl` reader + `Var`, `If`, `Return` builders |
| `@Watch` | BodyMacro | Attribute argument parsing + code block manipulation |
| `@MemberwiseInit` | MemberMacro | `StructDecl` reader + `Init`, `Arg` builders |
| `@CustomCodingKeys` | MemberMacro | `StructDecl` reader + `Enum`, `Case` builders |

## Architecture

```
Sources/MacroSyn/
├── Reader/
│   ├── SyntaxReader.swift       — Core protocol + trait extensions
│   ├── TraitsReader.swift       — Modifier, inheritance, generic traits
│   ├── Expressions.swift        — Literal and collection expression readers
│   └── Initializer.swift        — Initializer declaration reader
├── Builder/
│   ├── DSL/
│   │   ├── Arg.swift            — ArgType protocol + Arg parameter descriptor
│   │   ├── Decl.swift           — TypeRef, Var, StoredVar, Func, Init builders
│   │   ├── TypeDecl.swift       — Struct, Class, Enum, Extension, Case builders
│   │   ├── Stmt.swift           — If, Guard, Return, For, While, Throw, Switch, Do/Catch
│   │   └── Expr.swift           — Literal values
│   └── Interpolation.swift      — SyntaxStringInterpolation extensions
├── StructDecl.swift             — Struct declaration reader
├── ClassDecl.swift              — Class declaration reader
├── EnumDecl.swift               — Enum declaration + case readers
├── ActorDecl.swift              — Actor declaration reader
├── ProtocolDecl.swift           — Protocol declaration + associated type readers
├── Function.swift               — Function + Parameter readers
├── Variable.swift               — Variable reader (binding analysis, tuple destructuring)
├── Property.swift               — Property typealias + stored property detection
├── GroupDecl.swift               — Shared DeclGroupSyntax member accessors
├── Attribute.swift              — Attribute reader
├── CodeBlock.swift              — Statement + CodeBlock readers
└── Diagnostics.swift            — DiagnosticBuilder + ergonomic extensions
```

## Requirements

- Swift 6.0+
- SwiftSyntax 600.0+

## License

See [LICENSE](LICENSE) for details.
