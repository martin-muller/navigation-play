// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FeatureA",
    platforms: [
        .iOS(.v17)
      ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FeatureA",
            targets: ["FeatureA"]),
    ],
    dependencies: [
        .package(url: "https://github.com/martin-muller/swift-composable-architecture.git", branch: "feature/less-strict-stack-state"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FeatureA",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        
        ),
        .testTarget(
            name: "FeatureATests",
            dependencies: ["FeatureA",
                           
                          ]),
    ]
)
