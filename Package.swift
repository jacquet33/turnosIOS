// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TurnReserved",
    platforms: [.iOS(.v16)],
    targets: [
        .executableTarget(
            name: "TurnReserved",
            path: "TurnReserved"
        )
    ]
)
