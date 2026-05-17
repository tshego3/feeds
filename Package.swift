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
    // dependencies: [
    //     .package(url: "https://github.com/some/library.git", from: "1.0.0"),
    // ],

    targets: [
        // A target ≈ a project in a C# solution.
        // .executableTarget = console app / entry point project.
        // By convention, source files live in Sources/<TargetName>/
        .executableTarget(
            name: "Feeds",
            resources: [.process("Resources")]  // bundles feeds.json into the app
            // dependencies: []                     // add package dependencies here
        ),
        .testTarget(
            name: "FeedsTests",
            dependencies: ["Feeds"]
        ),
    ]
)
