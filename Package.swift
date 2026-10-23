// swift-tools-version: 6.0
// The fiery red jade for Firebase persistence.
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Carnelian",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1),
    ],
    products: [
        // The main library: declare your Firebase collections with annotations.
        .library(name: "Carnelian", targets: ["Carnelian"]),
        // Test helpers (MockClient) — mirror of JadeTesting. Excluded from release.
        .library(name: "CarnelianTesting", targets: ["CarnelianTesting"]),
    ],
    dependencies: [
        // Macro plumbing.
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
        // Firestore / Firebase.
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0"),
    ],
    targets: [
        // The macro implementation — where @Repository / @Collection / @Document expand.
        .macro(
            name: "CarnelianMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        // The public API surface.
        .target(
            name: "Carnelian",
            dependencies: [
                "CarnelianMacros",
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
            ]
        ),
        // Hand-mockable client for tests without a network.
        .target(
            name: "CarnelianTesting",
            dependencies: ["Carnelian"]
        ),
        .testTarget(
            name: "CarnelianTests",
            dependencies: [
                "Carnelian",
                "CarnelianTesting",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
