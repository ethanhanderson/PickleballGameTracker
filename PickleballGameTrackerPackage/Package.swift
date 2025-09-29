// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "GameTrackerFeature",
  platforms: [
    .iOS(.v26),
    .macOS(.v14)
  ],
  products: [
    .library(
      name: "GameTrackerFeature",
      targets: ["GameTrackerFeature"]
    )
  ],
  dependencies: [
    .package(path: "../PickleballGameTrackerCorePackage")
  ],
  targets: [
    .target(
      name: "GameTrackerFeature",
      dependencies: [
        .product(
          name: "GameTrackerCore", package: "PickleballGameTrackerCorePackage")
      ]
    ),
    .testTarget(
      name: "GameTrackerFeatureTests",
      dependencies: ["GameTrackerFeature"]
    ),
  ]
)
