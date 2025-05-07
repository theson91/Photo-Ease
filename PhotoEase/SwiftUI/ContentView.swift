import SwiftUI

struct ContentView: UIViewControllerRepresentable {

    typealias UIViewControllerType = UINavigationController

    func makeUIViewController(context: Context) -> UINavigationController {
        let viewController = PhotosListViewController(nibName: "PhotosListViewController", bundle: nil)
        let navigationController = UINavigationController(rootViewController: viewController)
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        
    }
}
