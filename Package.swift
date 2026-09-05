// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ExpenseTracker",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ExpenseTracker",
            targets: ["ExpenseTracker"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ExpenseTracker",
            dependencies: [],
            path: ".",
            exclude: ["Tests", "README.md"],
            sources: [
                "ExpenseTrackerApp.swift",
                "Models",
                "Services",
                "ViewModels",
                "Views",
                "Intents"
            ]
        ),
        .testTarget(
            name: "ExpenseTrackerTests",
            dependencies: ["ExpenseTracker"],
            path: "Tests"
        )
    ]
)
