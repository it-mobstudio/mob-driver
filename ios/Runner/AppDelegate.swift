import UIKit
import Flutter
import GoogleMaps
import ContactsUI

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, CNContactPickerDelegate {
  private let contactPickerChannel = "m_o_b_demand_side/contact_picker"
  private var contactPickerMethodChannel: FlutterMethodChannel?
  private var pendingContactResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Keep native map initialization aligned with AppConfig and Android.
    // A fresh checkout may not have the ignored Secrets.xcconfig file; in
    // that case Info.plist contains the unresolved build variable and the
    // Google Maps SDK terminates the app as soon as Add Address opens a map.
    let fallbackMapsApiKey = "AIzaSyC_dvw8b7g1e1RB9dQj4rAnFyxGD1S2s7Y"
    let configuredMapsApiKey =
      (Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines)
    let mapsApiKey = configuredMapsApiKey.flatMap {
      !$0.isEmpty && !$0.contains("$(") ? $0 : nil
    } ?? fallbackMapsApiKey
    GMSServices.provideAPIKey(mapsApiKey)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    setupContactPickerChannel(
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
  }

  private func setupContactPickerChannel(binaryMessenger: FlutterBinaryMessenger) {
    guard contactPickerMethodChannel == nil else { return }
    let channel = FlutterMethodChannel(
      name: contactPickerChannel,
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "pickPhoneContact" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.pickPhoneContact(result: result)
    }
    contactPickerMethodChannel = channel
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
    guard let presenter = activeViewController else {
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

  private var activeViewController: UIViewController? {
    let activeWindow = window ?? UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }

    var controller = activeWindow?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
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
