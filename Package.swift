// swift-tools-version:5.1

import PackageDescription

let package = Package(
  name: "Schedulability",
  products: [
    .executable(name: "schedulability", targets: ["schedulability"]),
  ],
  dependencies: [
    .package(url: "https://github.com/kyouko-taiga/DDKit.git", from: "2.0.0"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "0.0.1"),
  ],
  targets: [
    .target(name: "schedulability", dependencies: [
      "SchedulabilityLib",
      .product(name: "ArgumentParser", package: "swift-argument-parser"),
    ]),
    .target(name: "SchedulabilityLib", dependencies: ["DDKit"]),
    .testTarget(name: "SchedulabilityLibTests", dependencies: ["SchedulabilityLib"]),
  ])
