import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let kShareChannelName = "com.example.yank/share_receiver"
  private let kAppGroupId = "group.com.example.yank"
  private let kShareKey = "ShareKey"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as? FlutterViewController
    if let messenger = controller?.binaryMessenger {
      setupShareChannel(messenger: messenger)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ShareReceiver") {
      setupShareChannel(messenger: registrar.messenger())
    }
  }

  private func setupShareChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: kShareChannelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      let userDefaults = UserDefaults(suiteName: self.kAppGroupId)

      switch call.method {
      case "getPendingShares":
        if let data = userDefaults?.data(forKey: self.kShareKey),
           let jsonString = String(data: data, encoding: .utf8) {
          result(jsonString)
        } else {
          result(nil)
        }
      case "clearPendingShares":
        userDefaults?.removeObject(forKey: self.kShareKey)
        userDefaults?.synchronize()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
