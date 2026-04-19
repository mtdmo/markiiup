// swift-tools-version: 6.2
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
        )
    ]
)
