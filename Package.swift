// swift-tools-version:5.1

import PackageDescription

let package = Package(
  name: "Schedulability",
  products: [
    .executable(name: "schedulability", targets: ["schedulability"]),
  ],
  dependencies: [
    .package(url: "https://github.com/kyouko-taiga/DDKit.git", from: "2.0.0"),
  ],
  targets: [
    .target(name: "schedulability", dependencies: ["SchedulabilityLib"]),
    .target(name: "SchedulabilityLib", dependencies: ["DDKit"]),
    .testTarget(name: "SchedulabilityLibTests", dependencies: ["SchedulabilityLib"]),
  ])
