import UIKit
import Flutter
import GoogleMaps
import FirebaseCore

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Inicializar o Google Maps
    GMSServices.provideAPIKey("AIzaSyD1oWEc2G4-VvqMyETk1DOnkoJe8l64DEI")

    // Inicializar o Firebase
    FirebaseApp.configure()

    // Registrar os plugins do Flutter
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
