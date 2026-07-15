import UIKit
import Flutter
import GoogleMaps
import ContactsUI

@main
@objc class AppDelegate: FlutterAppDelegate, CNContactPickerDelegate {
  private let contactPickerChannel = "m_o_b_demand_side/contact_picker"
  private var pendingContactResult: FlutterResult?

  // This app opts into the UIScene lifecycle (see Info.plist's
  // UIApplicationSceneManifest, using FlutterSceneDelegate). Under that
  // lifecycle, `didFinishLaunchingWithOptions` runs BEFORE the scene
  // connects its window — so `window` was still nil there, the
  // `rootViewController as? FlutterViewController` cast silently failed,
  // and the channel handler never got registered. Every Dart-side call
  // then hit MissingPluginException, which is exactly the "Contact picker
  // is available on mobile devices" fallback message. Overriding `window`
  // to add a didSet observer instead means setup runs whenever the window
  // actually becomes available, regardless of scene vs. non-scene timing.
  override var window: UIWindow? {
    didSet {
      setupContactPickerChannel()
    }
  }

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
    setupContactPickerChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func setupContactPickerChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else { return }
    let channel = FlutterMethodChannel(
      name: contactPickerChannel,
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "pickPhoneContact" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.pickPhoneContact(result: result)
    }
  }

  private func pickPhoneContact(result: @escaping FlutterResult) {
    if pendingContactResult != nil {
      result(FlutterError(
        code: "IN_PROGRESS",
        message: "Contact picker is already open.",
        details: nil
      ))
      return
    }

    pendingContactResult = result
    guard let presenter = window?.rootViewController else {
      pendingContactResult = nil
      result(FlutterError(
        code: "UNAVAILABLE",
        message: "Unable to open contact picker.",
        details: nil
      ))
      return
    }
    let picker = CNContactPickerViewController()
    picker.delegate = self
    picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
    presenter.present(picker, animated: true)
  }

  func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
    pendingContactResult?(FlutterError(
      code: "CANCELLED",
      message: "Contact selection cancelled.",
      details: nil
    ))
    pendingContactResult = nil
  }

  func contactPicker(
    _ picker: CNContactPickerViewController,
    didSelect contactProperty: CNContactProperty
  ) {
    let phoneNumber = (contactProperty.value as? CNPhoneNumber)?.stringValue ?? ""
    sendContact(contact: contactProperty.contact, phoneNumber: phoneNumber)
  }

  func contactPicker(
    _ picker: CNContactPickerViewController,
    didSelect contact: CNContact
  ) {
    let phoneNumber = contact.phoneNumbers.first?.value.stringValue ?? ""
    sendContact(contact: contact, phoneNumber: phoneNumber)
  }

  private func sendContact(contact: CNContact, phoneNumber: String) {
    let displayName = CNContactFormatter.string(
      from: contact,
      style: .fullName
    ) ?? ""
    pendingContactResult?([
      "name": displayName,
      "phone": phoneNumber
    ])
    pendingContactResult = nil
  }
}
