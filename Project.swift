import ProjectDescription

let project = Project(
    name: "IdentityKit",
    targets: [
        .target(
            name: "IdentityKit",
            destinations: [.iPhone, .iPad, .mac],
            product: .staticFramework,
            bundleId: "dev.peterfriese.IdentityKit",
            deploymentTargets: .multiplatform(iOS: "26.0", macOS: "26.0"),
            infoPlist: .default,
            sources: ["Sources/IdentityKit/**"],
            resources: ["Sources/IdentityKit/Assets.xcassets/**"],
            dependencies: [
                .external(name: "FirebaseAuth"),
                .external(name: "FirebaseStorage"),
                .external(name: "GoogleSignIn"),
            ],
            settings: .settings(
                base: [
                    "SWIFT_USE_EXPLICIT_MODULES": "NO",
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "YGAZHQXHH4",
                ]
            )
        ),
    ]
)
