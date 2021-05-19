// swift-tools-version:5.3
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
        .package(url: "https://gitlab-4d.private.4d.fr/qmobile/QMobileAPI.git" , .revision("HEAD")),
        .package(url: "https://gitlab-4d.private.4d.fr/qmobile/QMobileDataStore.git" , .revision("HEAD")),
        .package(url: "https://gitlab-4d.private.4d.fr/qmobile/QMobileDataSync.git" , .revision("HEAD")),
        .package(url: "https://gitlab-4d.private.4d.fr/qmobile/QMobileUI.git" , .revision("HEAD")),
        /*.package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0"),
        .package(url: "https://github.com/DaveWoodCom/XCGLogger.git", from: "7.0.0"),
        .package(url: "https://github.com/Moya/Moya.git", from: "14.0.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.9"),
        .package(url: "https://github.com/nvzqz/FileKit.git", from: "6.0.0"),
        .package(url: "https://github.com/phimage/CallbackURLKit.git", .revision("HEAD")),
        .package(url: "https://github.com/phimage/Prephirences.git", from: "5.1.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "5.13.4")
        .package(url: "https://github.com/phimage/ValueTransformerKit.git" , from: "1.2.3")
//        .package(url: "https://github.com/SwiftKickMobile/SwiftMessages.git", from: "7.0.0"), // No Package.swift file
        .package(url: "https://github.com/phimage/SwiftMessages.git", .revision("HEAD")), // https://github.com/SwiftKickMobile/SwiftMessages/pull/297
        .package(url: "https://github.com/xmartlabs/Eureka.git", from: "5.3.2"),
        .package(url: "https://github.com/thebluepotato/Eureka.git", .branch("spm")), // https://github.com/xmartlabs/Eureka/pull/1877
        .package(url: "https://github.com/IBAnimatable/IBAnimatable.git", .revision("HEAD"))
*/
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SDK",
            dependencies: [
                "QMobileAPI",
                "QMobileDataStore",
                "QMobileDataSync",
                "QMobileUI"/*,
                "Alamofire",
                "XCGLogger",
                "Moya",
                "SwiftyJSON",
                "ZIPFoundation",
                "FileKit",
                "CallbackURLKit",
                "Prephirences"*/
            ],
            path: "Sources"),
        .testTarget(
            name: "SDKTests",
            dependencies: ["SDK"],
            path: "Tests")
    ]
)
