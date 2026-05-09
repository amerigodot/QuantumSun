// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "quantum-sun",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "quantum-sun", targets: ["quantum-sun"]),
        .library(name: "QuantumSunCore", targets: ["QuantumSunCore"])
    ],
    targets: [
        .target(
            name: "QuantumSunCore",
            dependencies: []),
        .executableTarget(
            name: "quantum-sun",
            dependencies: ["QuantumSunCore"]),
    ]
)