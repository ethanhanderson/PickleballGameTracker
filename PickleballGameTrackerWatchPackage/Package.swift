// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "GameTrackerWatchFeature",
  platforms: [
    .watchOS(.v26)
  ],
  products: [
    .library(
      name: "GameTrackerWatchFeature",
      targets: ["GameTrackerWatchFeature"]
    )
  ],
  dependencies: [
    .package(path: "../PickleballGameTrackerCorePackage")
  ],
  targets: [
    .target(
      name: "GameTrackerWatchFeature",
      dependencies: [
        .product(name: "GameTrackerCore", package: "PickleballGameTrackerCorePackage")
      ]
    ),
    .testTarget(
      name: "GameTrackerWatchFeatureTests",
      dependencies: ["GameTrackerWatchFeature"]
    ),
  ]
)
