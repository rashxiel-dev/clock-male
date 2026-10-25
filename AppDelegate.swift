import UIKit
import WebKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = WebViewController()
        window?.makeKeyAndVisible()
        application.isIdleTimerDisabled = true   // keeps the screen awake
        return true
    }
}

class WebViewController: UIViewController {
    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.95, green: 0.94, blue: 0.98, alpha: 1)
        let web = WKWebView(frame: view.bounds, configuration: WKWebViewConfiguration())
        web.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        web.scrollView.bounces = false
        view.addSubview(web)
        if let page = Bundle.main.url(forResource: "index", withExtension: "html") {
            web.loadFileURL(page, allowingReadAccessTo: page.deletingLastPathComponent())
        }
    }
}
