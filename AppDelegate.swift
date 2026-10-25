import UIKit
import WebKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    // Screen stays on only between these hours (device time); outside them the iPad may sleep.
    let awakeFrom = 6, awakeUntil = 22

    func updateAwake() {
        let h = Calendar.current.component(.hour, from: Date())
        UIApplication.shared.isIdleTimerDisabled = (h >= awakeFrom && h < awakeUntil)
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = WebViewController()
        window?.makeKeyAndVisible()
        updateAwake()
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in self?.updateAwake() }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) { updateAwake() }
}

class WebViewController: UIViewController, WKScriptMessageHandler {
    var web: WKWebView!
    var dimmed = false
    var savedBrightness: CGFloat = 0.5

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.95, green: 0.94, blue: 0.98, alpha: 1)
        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "power")
        config.userContentController.add(self, name: "ical")
        web = WKWebView(frame: view.bounds, configuration: config)
        web.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        web.scrollView.bounces = false
        view.addSubview(web)
        if let page = Bundle.main.url(forResource: "index", withExtension: "html") {
            web.loadFileURL(page, allowingReadAccessTo: page.deletingLastPathComponent())
        }
    }

    // The page asks to dim the screen when idle and restore it on touch.
    func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
        if m.name == "ical" {
            // Download the Google Calendar secret iCal link and hand the text to the page (read-only).
            guard let u = m.body as? String, let url = URL(string: u), url.scheme == "https" else { return }
            URLSession.shared.dataTask(with: url) { data, _, _ in
                let text = data.map { String(decoding: $0, as: UTF8.self) } ?? ""
                guard let j = try? JSONSerialization.data(withJSONObject: [text]),
                      let arg = String(data: j, encoding: .utf8) else { return }
                DispatchQueue.main.async { self.web.evaluateJavaScript("window.onIcs(\(arg)[0])", completionHandler: nil) }
            }.resume()
            return
        }
        if (m.body as? String) == "dim" {
            if !dimmed { savedBrightness = UIScreen.main.brightness; dimmed = true }
            UIScreen.main.brightness = 0.12
        } else if dimmed {
            UIScreen.main.brightness = savedBrightness; dimmed = false
        }
    }
}
