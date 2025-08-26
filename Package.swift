// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KoreanLunarCalendarSwift",
    platforms: [
        .iOS(.v13), .macOS(.v12), .tvOS(.v13), .watchOS(.v6)
    ],
    products: [
        .library(name: "KoreanLunarCalendar", targets: ["KoreanLunarCalendar"]),
    ],
    targets: [
        .target(
            name: "KoreanLunarCalendar",
            resources: [
                .process("Data")
            ]
        ),
        .testTarget(
            name: "KoreanLunarCalendarTests",
            dependencies: ["KoreanLunarCalendar"]
        ),
    ]
)