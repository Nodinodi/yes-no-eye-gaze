// swift-tools-version: 5.8

// Swift Playgrounds app project for the YES / NO eye-gaze app.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "YES NO",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "YES NO",
            targets: ["AppModule"],
            bundleIdentifier: "com.dino.yesno",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .leaf),
            accentColor: .presetColor(.green),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ]
)
