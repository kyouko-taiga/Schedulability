// swift-tools-version:5.1

import PackageDescription

let package = Package(
  name: "Schedulability",
  products: [
    .executable(name: "Schedulability", targets: ["Schedulability"]),
  ],
  dependencies: [
    .package(url: "https://github.com/kyouko-taiga/DDKit.git", from: "2.0.0"),
  ],
  targets: [
    .target(name: "Schedulability", dependencies: ["DDKit"]),
  ])
