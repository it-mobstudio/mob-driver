import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = (Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines),
       !apiKey.isEmpty,
       !apiKey.contains("$(") {
      GMSServices.provideAPIKey(apiKey)
    } else {
      NSLog("Google Maps iOS API key is missing. Add GOOGLE_MAPS_API_KEY to ios/Flutter/Secrets.xcconfig.")
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
