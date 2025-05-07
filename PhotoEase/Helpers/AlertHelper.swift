//
//  AlertHelper.swift
//  PhotoEase
//
//  Created by Son on 28/02/2025.
//

import Foundation
import UIKit

class AlertHelper {

    class func showConfirmation(from viewController: UIViewController, title: String? = nil, message: String, confirmActionTitle: String, cancelActionTitle: String, confirmAction: @escaping () -> ()) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: confirmActionTitle, style: .destructive) { _ in
            confirmAction()
        }
        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .cancel)
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        viewController.present(alertController, animated: true)
    }
    
    class func showErrorMessage(from viewController:UIViewController, title: String? = NSLocalizedString("Error", comment: "Title of error message"), message: String, closeAction: (() -> ())? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let closeAction = UIAlertAction(title: NSLocalizedString("Action-Title-Close", comment: ""), style: .default) { _ in
            closeAction?()
        }
        alertController.addAction(closeAction)
        viewController.present(alertController, animated: true)
    }
}
