// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "FuturaAsync",
    products: [
        .library(
            name: "FuturaAsync",
            targets: ["FuturaAsync"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "FuturaAsync",
            dependencies: []),
        .testTarget(
            name: "FuturaAsyncTests",
            dependencies: ["FuturaAsync"]),
    ]
)
