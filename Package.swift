// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SwiftCIFP",
  defaultLocalization: "en",
  platforms: [.macOS(.v26), .iOS(.v26), .watchOS(.v26), .tvOS(.v26), .visionOS(.v26)],
  products: [
    .library(
      name: "SwiftCIFP",
      targets: ["SwiftCIFP"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.7.0"),
    .package(url: "https://github.com/swiftlang/swift-docc-plugin.git", from: "1.4.3"),
    .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.20"),
    .package(url: "https://github.com/jkandzi/Progress.swift.git", from: "0.4.0")
  ],
  targets: [
    .target(
      name: "SwiftCIFP",
      resources: [.process("Resources")]
    ),
    .testTarget(
      name: "SwiftCIFPTests",
      dependencies: ["SwiftCIFP"]
    ),
    .executableTarget(
      name: "SwiftCIFP_E2E",
      dependencies: [
        "SwiftCIFP",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "ZIPFoundation", package: "ZIPFoundation"),
        .product(name: "Progress", package: "Progress.swift")
      ]
    )
  ],
  swiftLanguageModes: [.v5, .v6]
)
