// swift-tools-version: 6.2
//
// Package.swift — like a .csproj file in C#.
// Declares the project name, platform targets, dependencies, and build targets.
// "import PackageDescription" is like "using" in C# — it imports a module (namespace).

import PackageDescription

// "let" declares an immutable variable (like "readonly" in C#).
// Package(...) is a struct initializer (similar to calling "new Package { ... }" in C#).
let package = Package(
    name: "Feeds",

    // C# equivalent: <TargetFramework> in .csproj
    // Required for SwiftUI — restricts to macOS 14+ / iOS 17+
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],

    // Dependencies = NuGet packages. Fetched from Git repos instead of a package registry.
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift-lm", .upToNextMajor(from: "3.31.3")),
        .package(url: "https://github.com/huggingface/swift-huggingface", from: "0.9.0"),
        .package(url: "https://github.com/huggingface/swift-transformers", from: "1.3.0"),
    ],

    targets: [
        // A target ≈ a project in a C# solution.
        // .executableTarget = console app / entry point project.
        // By convention, source files live in Sources/<TargetName>/
        .executableTarget(
            name: "Feeds",
            dependencies: [
                .product(name: "MLXLLM", package: "mlx-swift-lm", condition: .when(platforms: [.macOS, .iOS])),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm", condition: .when(platforms: [.macOS, .iOS])),
                .product(name: "MLXHuggingFace", package: "mlx-swift-lm", condition: .when(platforms: [.macOS, .iOS])),
                .product(name: "HuggingFace", package: "swift-huggingface", condition: .when(platforms: [.macOS, .iOS])),
                .product(name: "Tokenizers", package: "swift-transformers", condition: .when(platforms: [.macOS, .iOS])),
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "FeedsTests",
            dependencies: ["Feeds"]
        ),
    ]
)
