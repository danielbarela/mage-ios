// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LayerFetch",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "LayerFetch",
            targets: ["LayerFetch"]
        ),
    ],
    dependencies: [
        .package(name: "FetchOperation", path: "../FetchOperation"),
        .package(name: "ServerDTO", path: "../ServerDTO"),
        .package(name: "Layer", path: "../Layer"),
        .package(name: "APIRouter", path: "../APIRouter")
    ],
    targets: [
        .target(
            name: "LayerFetch",
            dependencies: [
                .product(name: "FetchOperation", package: "FetchOperation"),
                .product(name: "ServerDTO", package: "ServerDTO"),
                .product(name: "Layer", package: "Layer"),
                .product(name: "APIRouter", package: "APIRouter")
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error) // Treat all warnings as errors for this target
            ]
        ),
        .testTarget(
            name: "LayerFetchTests",
            dependencies: ["LayerFetch"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
