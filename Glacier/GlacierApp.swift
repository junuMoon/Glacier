import SwiftUI

@main
struct GlacierApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: GlacierController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller = GlacierController()
    }
}
