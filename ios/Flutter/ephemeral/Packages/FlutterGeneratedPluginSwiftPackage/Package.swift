// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "audio_session", path: "../.packages/audio_session-0.2.3"),
        .package(name: "file_picker", path: "../.packages/file_picker-11.0.2"),
        .package(name: "firebase_analytics", path: "../.packages/firebase_analytics-12.4.3"),
        .package(name: "firebase_core", path: "../.packages/firebase_core-4.11.0"),
        .package(name: "firebase_crashlytics", path: "../.packages/firebase_crashlytics-5.2.4"),
        .package(name: "firebase_messaging", path: "../.packages/firebase_messaging-16.4.1"),
        .package(name: "firebase_performance", path: "../.packages/firebase_performance-0.11.4+3"),
        .package(name: "flutter_local_notifications", path: "../.packages/flutter_local_notifications-19.5.0"),
        .package(name: "flutter_secure_storage_darwin", path: "../.packages/flutter_secure_storage_darwin-0.3.2"),
        .package(name: "geocoding_ios", path: "../.packages/geocoding_ios-3.1.0"),
        .package(name: "geolocator_apple", path: "../.packages/geolocator_apple-2.3.14"),
        .package(name: "image_picker_ios", path: "../.packages/image_picker_ios-0.8.13+6"),
        .package(name: "just_audio", path: "../.packages/just_audio-0.10.5"),
        .package(name: "package_info_plus", path: "../.packages/package_info_plus-9.0.1"),
        .package(name: "permission_handler_apple", path: "../.packages/permission_handler_apple-9.4.10"),
        .package(name: "record_ios", path: "../.packages/record_ios-2.1.1"),
        .package(name: "sentry_flutter", path: "../.packages/sentry_flutter-8.14.2"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.5.6"),
        .package(name: "sqflite_darwin", path: "../.packages/sqflite_darwin-2.4.3"),
        .package(name: "url_launcher_ios", path: "../.packages/url_launcher_ios-6.4.1"),
        .package(name: "webview_flutter_wkwebview", path: "../.packages/webview_flutter_wkwebview-3.26.0"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "audio-session", package: "audio_session"),
                .product(name: "file-picker", package: "file_picker"),
                .product(name: "firebase-analytics", package: "firebase_analytics"),
                .product(name: "firebase-core", package: "firebase_core"),
                .product(name: "firebase-crashlytics", package: "firebase_crashlytics"),
                .product(name: "firebase-messaging", package: "firebase_messaging"),
                .product(name: "firebase-performance", package: "firebase_performance"),
                .product(name: "flutter-local-notifications", package: "flutter_local_notifications"),
                .product(name: "flutter-secure-storage-darwin", package: "flutter_secure_storage_darwin"),
                .product(name: "geocoding-ios", package: "geocoding_ios"),
                .product(name: "geolocator-apple", package: "geolocator_apple"),
                .product(name: "image-picker-ios", package: "image_picker_ios"),
                .product(name: "just-audio", package: "just_audio"),
                .product(name: "package-info-plus", package: "package_info_plus"),
                .product(name: "permission-handler-apple", package: "permission_handler_apple"),
                .product(name: "record-ios", package: "record_ios"),
                .product(name: "sentry-flutter", package: "sentry_flutter"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "sqflite-darwin", package: "sqflite_darwin"),
                .product(name: "url-launcher-ios", package: "url_launcher_ios"),
                .product(name: "webview-flutter-wkwebview", package: "webview_flutter_wkwebview"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
