import SwiftUI
import Foundation

@main
struct OLMoE_swiftApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.font, .manrope())
                .environment(\.colorScheme, .dark)
                .preferredColorScheme(.dark)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    override init() {
        super.init()
#if targetEnvironment(simulator)
        // Disable Metal on simulator to avoid ggml_metal residency set crash.
        setenv("GGML_METAL_DISABLE", "1", 1)
#endif
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        print("Background URL session: \(identifier)")
        completionHandler()
    }
}
