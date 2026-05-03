// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "IdentityKit",
  platforms: [
    .iOS(.v26),
    .macOS(.v26)
  ],
  products: [
    .library(
      name: "IdentityKit",
      targets: ["IdentityKit"])
  ],
  dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.0.0")
  ],
  targets: [
    .target(
      name: "IdentityKit",
      dependencies: [
        .product(name: "FirebaseAuth", package: "firebase-ios-sdk")
      ]
    ),
    .testTarget(
      name: "IdentityKitTests",
      dependencies: ["IdentityKit"]
    ),
  ]
)
