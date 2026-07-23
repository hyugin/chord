// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "Chord",
  platforms: [
    .macOS(.v13),
  ],
  products: [
    .executable(name: "Chord", targets: ["Chord"]),
  ],
  targets: [
    .executableTarget(
      name: "Chord",
      path: "Sources/Chord",
      resources: [
        .copy("AppShortcuts/firefox-zen-shortcuts.json"),
      ]
    ),
    .testTarget(
      name: "ChordTests",
      dependencies: ["Chord"],
      path: "Tests/ChordTests",
      resources: [
        .copy("Fixtures"),
      ]
    ),
  ]
)
