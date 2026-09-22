import UIKit
import receive_sharing_intent

class ShareViewController: RSIShareViewController {

    // Return true to redirect directly to Yank without blocking on compose UI
    override func shouldAutoRedirect() -> Bool {
        return true
    }

}
