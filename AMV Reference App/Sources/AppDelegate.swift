import UIKit


@UIApplicationMain class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    // MARK: UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        if #available(iOS 11.0, *) {
            UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).textColor = UIColor(named: "Hellgrau")   // This handles an iOS 11 bug, radar #34758558
        }
        else {
            UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).textColor = UIColor(red: (225.0 / 255.0), green: (225.0 / 255.0), blue: (225.0 / 255.0), alpha: 1.0)
        }

        return true
    }
}
