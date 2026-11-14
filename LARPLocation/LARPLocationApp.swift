import SwiftUI
import UserNotifications

final class NotifDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotifDelegate()
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

@main
struct LARPLocationApp: App {
    @StateObject private var app = AppState()
    @StateObject private var perms = PermissionManager()

    init() {
        UNUserNotificationCenter.current().delegate = NotifDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(app)
                .environmentObject(perms)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        ZStack {
            switch app.stage {
            case 0: OnboardingView().transition(.opacity)
            case 1: PermissionsView().transition(.opacity)
            default: MainView().transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: app.stage)
    }
}
