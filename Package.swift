// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Swift_Repo",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Swift_Repo",
            targets: ["Swift_Repo"]
        ),
    ],
    targets: [
        .target(
            name: "Swift_Repo",
            dependencies: []
        ),
        .testTarget(
            name: "Swift_RepoTests",
            dependencies: ["Swift_Repo"]
        ),
    ]
)
