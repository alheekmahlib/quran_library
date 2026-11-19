// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "quran_library",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "quran-library", targets: ["quran_library"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/Quran-Lab/tajweedformer-apple", exact: "3.1.4"),
    ],
    targets: [
        .target(
            name: "quran_library",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "TajweedFormer", package: "tajweedformer-apple"),
            ],
            linkerSettings: [.linkedLibrary("TajweedFormerCore"), .linkedLibrary("c++")]
        ),
    ],
    swiftLanguageModes: [.v5]
)
