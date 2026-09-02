// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Form",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "Form",
            targets: ["Form"]
        ),
    ],
    dependencies: [
        .package(path: "../SendableExtensions"),
        .package(path: "../ServerDTO"),
        .package(path: "../Persistence"),
        .package(path: "../APIRouter"),
        .package(path: "../FetchOperation"),
        .package(path: "../UseCaseFactory"),
        .package(url: "https://github.com/ZipArchive/ZipArchive.git", from: "2.6.0"),
    ],
    targets: [
        .target(
            name: "Form",
            dependencies: [
                "SendableExtensions",
                "ServerDTO",
                "Persistence",
                "APIRouter",
                "FetchOperation",
                "UseCaseFactory",
                "ZipArchive"
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error)
            ]
        ),
        .testTarget(
            name: "FormTests",
            dependencies: [
                "Form",
                "ServerDTO"
            ],
            resources: [.process("Resources")]
        ),
    ],
    swiftLanguageModes: [.v6]
)
