// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ExtractBooks",
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/Swift-Kuery-SQLite.git", from: "1.1.0"),
        .package(url: "https://github.com/OpenKitten/MongoKitten.git", from: "4.0.0")
    ],
    targets: [
         .target(
            name: "ExtractBooks",
            dependencies: ["MongoKitten", "SwiftKuerySQLite"]),
    ]
)
