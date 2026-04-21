// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "markiiup",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "markiiupMac",
            targets: ["markiiupMac"]
        )
    ],
    targets: [
        .executableTarget(
            name: "markiiupMac"
        ),
        .testTarget(
            name: "markiiupMacTests",
            dependencies: ["markiiupMac"]
        )
    ]
)
