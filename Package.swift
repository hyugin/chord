// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "CHORD",
  platforms: [
    .macOS(.v13),
  ],
  products: [
    .executable(name: "CHORD", targets: ["CHORD"]),
  ],
  targets: [
    .executableTarget(
      name: "CHORD",
      path: "Sources/CHORD"
    ),
    .testTarget(
      name: "CHORDTests",
      dependencies: ["CHORD"],
      path: "Tests/CHORDTests",
      resources: [
        .copy("Fixtures"),
      ]
    ),
  ]
)
