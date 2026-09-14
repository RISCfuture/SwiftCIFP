// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let upcomingFeatures: [SwiftSetting] = [
  .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
  .enableUpcomingFeature("InferIsolatedConformances"),
  .enableUpcomingFeature("ImmutableWeakCaptures"),
  .enableUpcomingFeature("MemberImportVisibility"),
  .enableUpcomingFeature("ExistentialAny"),
  .enableUpcomingFeature("InternalImportsByDefault")
]

let package = Package(
  name: "SwiftCIFP",
  defaultLocalization: "en",
  platforms: [.macOS(.v13), .iOS(.v16), .watchOS(.v9), .tvOS(.v16), .visionOS(.v1)],
  products: [
    .library(
      name: "SwiftCIFP",
      targets: ["SwiftCIFP"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.8.2"),
    .package(url: "https://github.com/swiftlang/swift-docc-plugin.git", from: "1.5.0"),
    .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.20"),
    .package(url: "https://github.com/jkandzi/Progress.swift.git", from: "0.4.0")
  ],
  targets: [
    .target(
      name: "SwiftCIFP",
      resources: [.process("Resources")],
      swiftSettings: upcomingFeatures
    ),
    .testTarget(
      name: "SwiftCIFPTests",
      dependencies: ["SwiftCIFP"],
      swiftSettings: upcomingFeatures
    )
  ],
  swiftLanguageModes: [.v5, .v6]
)

package.targets.append(
  .executableTarget(
    name: "SwiftCIFP_E2E",
    dependencies: [
      "SwiftCIFP",
      .product(name: "ArgumentParser", package: "swift-argument-parser"),
      .product(name: "ZIPFoundation", package: "ZIPFoundation"),
      .product(name: "Progress", package: "Progress.swift")
    ],
    swiftSettings: upcomingFeatures
  )
)
