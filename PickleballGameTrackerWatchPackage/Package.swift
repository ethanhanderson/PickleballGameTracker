// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "PickleballGameTrackerWatchPackage",
  platforms: [
    .watchOS(.v11)
  ],
  products: [
    .library(
      name: "WatchFeature",
      targets: ["WatchFeature"]
    )
  ],
  dependencies: [
    .package(path: "../SharedGameCore")
  ],
  targets: [
    .target(
      name: "WatchFeature",
      dependencies: [
        .product(name: "SharedGameCore", package: "SharedGameCore")
      ],
      resources: [
        .process("Resources")
      ],
      swiftSettings: [
        .enableUpcomingFeature("StrictConcurrency")
      ]
    ),
    .testTarget(
      name: "WatchFeatureTests",
      dependencies: ["WatchFeature"]
    ),
  ]
)
