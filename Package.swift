// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "mint-update",
    products: [
        .executable(name: "mint-update", targets: ["mint-update"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/yonaskolb/Mint.git", from: "0.17.5")
    ],
    targets: [
        .executableTarget(
            name: "mint-update",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "MintKit", package: "Mint")
            ]
        ),
    ]
)
