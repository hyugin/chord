// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "CASK",
  platforms: [
    .macOS(.v13),
  ],
  products: [
    .executable(name: "CASK", targets: ["CASK"]),
  ],
  targets: [
    .executableTarget(
      name: "CASK",
      path: "Sources/CASK"
    ),
    .testTarget(
      name: "CASKTests",
      dependencies: ["CASK"],
      path: "Tests/CASKTests",
      resources: [
        .copy("Fixtures"),
      ]
    ),
  ]
)
