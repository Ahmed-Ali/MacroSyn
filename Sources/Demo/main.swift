//
//  main.swift
//
//  Created by Ahmed Ali (github.com/Ahmed-Ali) on 24/01/2026.
//

import ExampleLibrary

// MARK: - CaseDetection Demo

@CaseDetection
enum MyFancyEnum {
  case first, second
}

let v = MyFancyEnum.first
print("isFirst:", v.isFirst)

// MARK: - MemberwiseInit Demo

@MemberwiseInit
struct User {
  let name: String
  var age: Int
}

let user = User(name: "Ahmed", age: 30)
print("User:", user.name, user.age)

// MARK: - CustomCodingKeys Demo

@CustomCodingKeys
struct Profile: Codable {
  let firstName: String
  let lastName: String
  let profileURL: String
}

// CodingKeys enum is generated with snake_case raw values
print("Profile CodingKeys generated")

// MARK: - Watch Demo

class Counter {
  var count = 0

  @Watch("count")
  func increment() {
    count += 1
    print("Inside increment, count is now \(count)")
  }
}

let counter = Counter()
counter.increment()
counter.increment()
