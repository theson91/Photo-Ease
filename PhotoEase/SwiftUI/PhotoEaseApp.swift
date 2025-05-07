import SwiftUI

@main
struct PhotoEaseApp: App {
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .ignoresSafeArea() // To make the app's view to fill the entire screen
        }
    }
}
