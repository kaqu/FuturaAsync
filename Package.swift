// swift-tools-version:4.1

import PackageDescription

let package = Package(
    name: "FuturaAsync",
    products: [
        .library(
            name: "FuturaAsync",
            targets: ["FuturaAsync"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kaqu/FuturaFunc.git", .branch("master")),
    ],
    targets: [
        .target(
            name: "FuturaAsync",
            dependencies: ["FuturaFunc"]),
        .testTarget(
            name: "FuturaAsyncTests",
            dependencies: ["FuturaFunc", "FuturaAsync"]),
    ]
)
