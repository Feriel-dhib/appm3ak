import Flutter
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // FlutterAppDelegate already created the window + FlutterViewController
        // Attach the existing window to the UIWindowScene
        if let appDelegate = UIApplication.shared.delegate as? FlutterAppDelegate,
           let existingWindow = appDelegate.window {
            existingWindow.windowScene = windowScene
            self.window = existingWindow
        }
    }
}
