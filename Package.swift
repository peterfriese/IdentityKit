// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "IdentityKit",
  platforms: [
    .iOS(.v17)
  ],
  products: [
    .library(
      name: "IdentityKit",
      targets: ["IdentityKit"])
  ],
  targets: [
    .target(
      name: "IdentityKit"),
    .testTarget(
      name: "IdentityKitTests",
      dependencies: ["IdentityKit"]
    ),
  ]
)
