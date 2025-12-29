// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "llama",
    platforms: [.iOS(.v16)],
    products: [
        // App imports `llama` (xcframework module) and `llama_mtmd` (bridge)
        .library(name: "llama", targets: ["llama_bin", "llama_mtmd"])
    ],
    targets: [
        // Prebuilt llama.cpp runtime
        .binaryTarget(
            name: "llama_bin",
            path: "Frameworks/llama.xcframework"
        ),

        // Multimodal bridge target (vision only)
        .target(
            name: "llama_mtmd",
            dependencies: ["llama_bin"],
            path: "Sources/llama_mtmd",
            exclude: [
                // Do not compile CLI/tools
                "vendor/mtmd/mtmd-cli.cpp",
                "vendor/mtmd/mtmd-audio.cpp",
                "vendor/mtmd/mtmd/mtmd-audio.cpp",
                "vendor/mtmd/deprecation-warning.cpp",
                "vendor/mtmd/tests.sh",
                "vendor/mtmd/test-1.jpeg",
                "vendor/mtmd/test-2.mp3",
                "vendor/mtmd/legacy-models",
                "vendor/mtmd/requirements.txt"
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
                .headerSearchPath("vendor"),
                .headerSearchPath("vendor/mtmd"),
                .headerSearchPath("vendor/mtmd/models"),
                .headerSearchPath("vendor/miniaudio"),
                .headerSearchPath("vendor/stb"),
                .headerSearchPath("vendor/ggml")
            ],
            cxxSettings: [
                .headerSearchPath("include"),
                .headerSearchPath("vendor"),
                .headerSearchPath("vendor/mtmd"),
                .headerSearchPath("vendor/mtmd/models"),
                .headerSearchPath("vendor/miniaudio"),
                .headerSearchPath("vendor/stb"),
                .headerSearchPath("vendor/ggml"),
                .unsafeFlags(["-std=c++17"])
            ],
            linkerSettings: [
                .linkedFramework("Accelerate"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
                .linkedFramework("Foundation")
            ]
        )
    ]
)
