// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "GameTrackerFeature",
  platforms: [
    .iOS(.v26)
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
          name: "CorePackage", package: "PickleballGameTrackerCorePackage")
      ],
      swiftSettings: [
        .enableUpcomingFeature("StrictConcurrency")
      ]
    ),
    .testTarget(
      name: "GameTrackerFeatureTests",
      dependencies: ["GameTrackerFeature"]
    ),
  ]
)
