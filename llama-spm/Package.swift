// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "llama",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "llama", targets: ["llama", "llama_mtmd"])
    ],
    targets: [
        .binaryTarget(
            name: "llama",
            path: "Frameworks/llama.xcframework"
        ),
        .target(
            name: "llama_mtmd",
            dependencies: ["llama"],
            path: "Sources/llama_mtmd",
            publicHeadersPath: "include",
            cxxSettings: [
                .unsafeFlags(["-std=c++17"])
            ],
            linkerSettings: [
                .linkedFramework("Accelerate"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit")
            ]
        ),
        .testTarget(
            name: "llamaTests",
            dependencies: ["llama"],
            path: "Tests/llamaTests"
        )
    ]
)
