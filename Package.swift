// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SDK",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/4d/ios-QMobileAPI.git" , .revision("HEAD")),
        .package(url: "https://github.com/4d/ios-QMobileDataStore.git" , .revision("HEAD")),
        .package(url: "https://github.com/4d/ios-QMobileDataSync.git" , .revision("HEAD")),
        .package(url: "https://github.com/4d/ios-QMobileUI.git" , .revision("HEAD"))
    ],
    targets: [
        .target(
            name: "SDK",
            dependencies: [
                "QMobileAPI",
                "QMobileDataStore",
                "QMobileDataSync",
                "QMobileUI"
            ],
            path: "Sources"),
        .testTarget(
            name: "SDKTests",
            dependencies: ["SDK"],
            path: "Tests")
    ]
)
