// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StealthReader",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "StealthReader",
            path: "StealthReader"
        )
    ]
)
