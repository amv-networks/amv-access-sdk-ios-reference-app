import AMVKit
import UIKit


extension UIViewController {

    func displayErrorText(_ text: String, error: Error?) {
        OperationQueue.main.addOperation {
            self.navigationItem.title = text

            if let failure = error as? Failure {
                self.navigationItem.prompt = "\(failure)"
            }
            else if let serverError = error as? ServerError {
                self.navigationItem.prompt = "\(serverError.title): \(serverError.source) (\(serverError.detail))"
            }
            else if let error = error {
                self.navigationItem.prompt = error.localizedDescription
            }
            else {
                self.navigationItem.prompt = nil
            }
        }
    }
}
