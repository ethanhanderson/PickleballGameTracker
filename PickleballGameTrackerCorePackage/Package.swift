// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "CorePackage",
  platforms: [
    .iOS(.v26),
    .watchOS(.v26)
  ],
  products: [
    .library(
      name: "CorePackage",
      targets: ["CorePackage"]
    )
  ],
  targets: [
    .target(
      name: "CorePackage",
      path: "Sources/Core",
      resources: [
        .process("Assets.xcassets")
      ],
      swiftSettings: [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("StrictConcurrency"),
      ]
    ),
    .testTarget(
      name: "CorePackageTests",
      dependencies: ["orePackage"]
    ),
  ]
)
