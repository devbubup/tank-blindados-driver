import UIKit
import Flutter
import GoogleMaps
import FirebaseCore
import UserNotifications // Importar o UserNotifications para gerenciar notificações

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

        // Configuração para notificações
        configureUserNotifications(application)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Configura e solicita permissão para notificações
    private func configureUserNotifications(_ application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            print("Permissão de notificação concedida: \(granted), Erro: \(String(describing: error))")
            guard granted else { return }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }

    // Chamado quando o registro de APNs é bem-sucedido
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
    }

    // Chamado quando o registro de APNs falha
    override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Falha ao registrar para notificações: \(error)")
    }
}
