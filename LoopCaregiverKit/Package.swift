// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LoopCaregiverKit",
    platforms: [.iOS(.v16), .watchOS(.v10)],
    products: [
        .library(
            name: "LoopCaregiverKit",
            targets: ["LoopCaregiverKit", "LoopCaregiverKitUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/LoopKit/LoopKit.git", branch: "dev"),
        //.package(path: "../../LoopKit"),
        .package(url: "https://github.com/gestrich/NightscoutKit.git", branch: "feature/2023-07/bg/remote-commands"),
        .package(url: "https://github.com/mattrubin/OneTimePassword.git", branch: "develop"),
    ],
    targets: [
        .target(
            name: "LoopCaregiverKit",
            dependencies: [
                "LoopKit",
                "NightscoutKit",
                "OneTimePassword"
            ]
        ),
        .target(
            name: "LoopCaregiverKitUI",
            dependencies: [
                "LoopCaregiverKit",
                "LoopKit",
            ]
        ),
        .testTarget(
            name: "LoopCaregiverKitTests",
            dependencies: ["LoopCaregiverKit"]),
    ]
)
