// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "chat-package",
    platforms: [
        .iOS(.v10),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "chat-package",
            targets: ["chat-package"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "git@github.com:mendyEdri/lit-networking.git", .branch("master")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "chat-package",
            dependencies: []),
        .testTarget(
            name: "UnitTests",
            dependencies: ["chat-package", "lit-networking"]),
        .testTarget(
            name: "Integration Tests",
            dependencies: ["chat-package", "lit-networking"]),
    ]
)
