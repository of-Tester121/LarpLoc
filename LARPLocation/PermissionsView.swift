import SwiftUI

struct PermissionCard: View {
    let icon: String
    let title: String
    let detail: String
    let granted: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(LinearGradient(colors: [.neonPink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline).foregroundStyle(.white)
                Text(detail).font(.footnote).foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.green)
                    .transition(.scale)
            } else {
                Button("Allow", action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(.neonPink)
            }
        }
        .padding(16)
        .glass(24)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: granted)
    }
}

struct PermissionsView: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var perms: PermissionManager
    @State private var appear = false

    var body: some View {
        ZStack {
            AnimatedBackground()
            VStack(alignment: .leading, spacing: 20) {
                Spacer()
                Text("Almost there, \(app.name) 🔐")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("A couple of permissions to make the magic work.")
                    .foregroundStyle(.white.opacity(0.75))

                PermissionCard(icon: "location.fill",
                               title: "Location",
                               detail: "Shows your real position next to your fake one.",
                               granted: perms.locationGranted,
                               action: perms.requestLocation)
                    .offset(y: appear ? 0 : 40).opacity(appear ? 1 : 0)

                PermissionCard(icon: "bell.badge.fill",
                               title: "Notifications",
                               detail: "Get a ping every time you teleport.",
                               granted: perms.notifGranted,
                               action: perms.requestNotifications)
                    .offset(y: appear ? 0 : 60).opacity(appear ? 1 : 0)

                Spacer()

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation { app.stage = 2 }
                } label: {
                    Text(perms.locationGranted || perms.notifGranted ? "Enter LARP Location" : "Skip for now")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.15)) { appear = true }
        }
    }
}
