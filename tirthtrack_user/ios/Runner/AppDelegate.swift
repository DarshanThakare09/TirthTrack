import Flutter
import UIKit
import GoogleMaps // 1. Import the Google Maps SDK

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // 2. Provide your Google Maps API key here
        GMSServices.provideAPIKey("AIzaSyB1axqjEo3cWgYbIL0nNNwq_t3Pdl43B4g")

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }
}
