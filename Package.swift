// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SDK",
    platforms: [
        .iOS(.v12)
    ],
    dependencies: [
        .package(url: "http://srv-git:3000/qmobile/QMobileAPI.git" , .revision("HEAD")),
        .package(url: "http://srv-git:3000/qmobile/QMobileDataStore.git" , .revision("HEAD")),
        .package(url: "http://srv-git:3000/qmobile/QMobileDataSync.git" , .revision("HEAD")),
        .package(url: "http://srv-git:3000/qmobile/QMobileUI.git" , .revision("HEAD")),

        .package(url: "https://github.com/Alamofire/Alamofire.git" , from: "4.8.2"),
        .package(url: "https://github.com/DaveWoodCom/XCGLogger.git" , from: "7.0.0"),
        .package(url: "https://github.com/Moya/Moya.git" , from: "13.0.1"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git" , from: "5.0.0"),
        .package(url: "https://github.com/Thomvis/BrightFutures.git" , from: "8.0.1"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git" , from: "0.9.9"),
        .package(url: "https://github.com/nvzqz/FileKit.git" , from: "6.0.0"),
        .package(url: "https://github.com/phimage/CallbackURLKit.git" , .revision("HEAD")),
        .package(url: "https://github.com/phimage/Prephirences.git" , .revision("HEAD")),
        .package(url: "https://github.com/ArtSabintsev/Guitar.git", from: "1.0.2")

//        .package(url: "https://github.com/IBAnimatable/IBAnimatable.git", .revision("0776c5c099b308cd0cffe14f8cf89f0371153d03")), // not for macOS
//        .package(url: "https://github.com/onevcat/Kingfisher.git" , .revision("68b7aa28a1d9f03ac00f2eeb0c522422dcd562bb")), // not for macOS
//        .package(url: "https://github.com/devicekit/DeviceKit.git" , .revision("89452446badb4391899e989b8ae99c84488457f5")), // not for macOS
//        .package(url: "https://github.com/SwiftKickMobile/SwiftMessages.git" , from: "7.0.0") // No Package.swift file
//        .package(url: "https://github.com/phimage/ValueTransformerKit.git" , from: "1.2.1")
//        .package(url: "https://github.com/xmartlabs/Eureka.git" , from: "5.0.0") // No Package.swift file

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
                "QMobileUI",
                "Alamofire",
                "XCGLogger",
                "Moya",
                "SwiftyJSON",
                "BrightFutures",
                "ZIPFoundation",
                "FileKit",
                "CallbackURLKit",
                "Prephirences",
                "Guitar"
            ],
            path: "Sources"),
        .testTarget(
            name: "SDKTests",
            dependencies: ["SDK"],
            path: "Tests")
    ]
)
