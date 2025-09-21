// swift-tools-version: 6.0.0
import PackageDescription
import Foundation

let env = ProcessInfo.processInfo.environment
var swiftSettings: [SwiftSetting] = []
var linkerSettings: [LinkerSetting] = []

#if os(Windows)
if let includePath = env["SDL3_INCLUDE"] {
    // Pass the include path to the C compiler (Clang) via the Swift compiler.
    swiftSettings.append(.unsafeFlags(["-Xcc", "-I\(includePath)"]))
}

if let libPath = env["SDL3_LIB"] {
    linkerSettings.append(.unsafeFlags(["-L\(libPath)"]))
}
linkerSettings.append(.linkedLibrary("SDL3"))
#endif

let package = Package(
  name: "SwiftSDL",
  platforms: [
    .iOS(.v13),
    .tvOS(.v13),
    .macOS(.v10_15),
  ],
  products: [
    .library(name: "SwiftSDL", targets: ["SwiftSDL"]),
    .executable(name: "sdl", targets: ["SwiftSDL-TestBench"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    .package(url: "https://github.com/apple/swift-collections.git", .upToNextMinor(from: "1.1.4")),
  ],
  targets: [
    .binaryTarget(
      name: "SDL3",
      path: "Dependencies/SDL3.xcframework"
    ),
    
    .systemLibrary(
      name: "CSDL3",
      path: "Dependencies/CSDL3",
      pkgConfig: "sdl3",
      providers: [
        .apt(["libsdl3-dev"])
      ]),
    
    .target(
      name: "CSDL",
      dependencies: [ .target(name: "SDL3") ],
      path: "Dependencies/CSDL",
      cSettings: [
        .headerSearchPath("Sources/SDL3.xcframework/macos-arm64_x86_64/Headers", .when(platforms: [.macOS])),
        .headerSearchPath("Sources/SDL3.xcframework/ios-arm64/Headers", .when(platforms: [.iOS])),
        .headerSearchPath("Sources/SDL3.xcframework/tvos-arm64/Headers", .when(platforms: [.tvOS])),
      ]
    ),
    
    .target(
      name: "SwiftSDL",
      dependencies: [
        .target(name: "CSDL", condition: .when(platforms: [.macOS, .iOS, .tvOS])),
        .target(name: "CSDL3", condition: .when(platforms: [.linux, .windows])),
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ],
      swiftSettings: swiftSettings,   
      linkerSettings: linkerSettings 
    ),
    
    .executableTarget(
      name: "SwiftSDL-TestBench",
      dependencies: [
        "SwiftSDL",
        .product(name: "Collections", package: "swift-collections"),
      ],
      path: "Samples/SwiftSDL-TestBench",
      resources: [
        .process("Resources/")
      ]
    )
  ]
)
