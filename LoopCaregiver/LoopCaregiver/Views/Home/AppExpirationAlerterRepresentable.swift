import LoopKitUI
import SwiftUI
import UIKit

struct AppExpirationAlerterRepresentable: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UIViewController {
        AppExpirationAlerterViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}

class AppExpirationAlerterViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func appMovedToForeground() {
        AppExpirationAlerter.alertIfNeeded(viewControllerToPresentFrom: self)
    }
}
