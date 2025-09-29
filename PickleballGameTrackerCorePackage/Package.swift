// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "GameTrackerCore",
  platforms: [
    .iOS(.v26),
    .watchOS(.v26)
  ],
  products: [
    .library(
      name: "GameTrackerCore",
      targets: ["GameTrackerCore"]
    ),
  ],
  targets: [
    .target(
      name: "GameTrackerCore",
      path: "Sources/GameTrackerCore"
    ),
  ]
)
