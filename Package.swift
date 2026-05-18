// swift-tools-version: 6.2
//
// Package.swift — Dual-platform app (iOS + Android via Skip Fuse).
// Shared Swift code is built as a library consumed by both platforms.

import PackageDescription

let package = Package(
    name: "Feeds",

    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],

    products: [
        .library(name: "Feeds", type: .dynamic, targets: ["Feeds"]),
    ],

    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.6.35"),
        .package(url: "https://source.skip.tools/skip-fuse.git", from: "1.0.0"),
        .package(url: "https://source.skip.tools/skip-fuse-ui.git", from: "1.10.5"),
        .package(url: "https://source.skip.tools/skip-sql.git", from: "0.9.0"),
        .package(url: "https://github.com/ml-explore/mlx-swift-lm", .upToNextMajor(from: "3.31.3")),
        .package(url: "https://github.com/huggingface/swift-huggingface", from: "0.9.0"),
        .package(url: "https://github.com/huggingface/swift-transformers", from: "1.3.0"),
    ],

    targets: [
        .target(
            name: "Feeds",
            dependencies: [
                .product(name: "SkipFuse", package: "skip-fuse"),
                .product(name: "SkipFuseUI", package: "skip-fuse-ui"),
                .product(name: "SkipSQLPlus", package: "skip-sql"),
                .product(name: "MLXLLM", package: "mlx-swift-lm", condition: .when(platforms: [.macOS, .iOS])),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm", condition: .when(platforms: [.macOS, .iOS])),
                .product(name: "MLXHuggingFace", package: "mlx-swift-lm", condition: .when(platforms: [.macOS, .iOS])),
                .product(name: "HuggingFace", package: "swift-huggingface", condition: .when(platforms: [.macOS, .iOS])),
                .product(name: "Tokenizers", package: "swift-transformers", condition: .when(platforms: [.macOS, .iOS])),
            ],
            resources: [.process("Resources")],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),
        .testTarget(
            name: "FeedsTests",
            dependencies: ["Feeds"]
        ),
    ]
)
