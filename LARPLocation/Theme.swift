import SwiftUI

extension Color {
    static let neonPink = Color(red: 1.0, green: 0.28, blue: 0.62)
    static let neonCyan = Color(red: 0.25, green: 0.9, blue: 1.0)
    static let deepNight = Color(red: 0.06, green: 0.04, blue: 0.16)
}

extension View {
    func glass(_ radius: CGFloat = 22) -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
    }

    func circleButton() -> some View {
        self
            .font(.headline)
            .foregroundStyle(.white)
            .frame(width: 46, height: 46)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(LinearGradient(colors: [.neonPink, .purple], startPoint: .leading, endPoint: .trailing), in: Capsule())
            .shadow(color: Color.neonPink.opacity(0.5), radius: 12, y: 6)
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(configuration.isPressed ? 0.25 : 0.14), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct AnimatedBackground: View {
    @State private var move = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [.deepNight, Color(red: 0.16, green: 0.05, blue: 0.3)],
                           startPoint: .top, endPoint: .bottom)
            Circle().fill(Color.neonPink.opacity(0.55)).frame(width: 340)
                .blur(radius: 90)
                .offset(x: move ? 130 : -130, y: move ? -240 : -120)
            Circle().fill(Color.neonCyan.opacity(0.4)).frame(width: 300)
                .blur(radius: 90)
                .offset(x: move ? -120 : 140, y: move ? 260 : 120)
            Circle().fill(Color.purple.opacity(0.5)).frame(width: 260)
                .blur(radius: 80)
                .offset(x: move ? 80 : -80, y: move ? 40 : 180)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) { move.toggle() }
        }
    }
}

struct ProgressDots: View {
    let count: Int
    let index: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? Color.white : Color.white.opacity(0.3))
                    .frame(width: i == index ? 28 : 8, height: 8)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: index)
    }
}

struct PulseDot: View {
    @State private var pulse = false
    var body: some View {
        ZStack {
            Circle().fill(Color.neonPink.opacity(0.35))
                .frame(width: 60, height: 60)
                .scaleEffect(pulse ? 1.7 : 0.5)
                .opacity(pulse ? 0 : 1)
            Circle().fill(Color.neonPink)
                .frame(width: 22, height: 22)
                .overlay(Circle().stroke(.white, lineWidth: 3))
                .shadow(color: .neonPink, radius: 8)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) { pulse = true }
        }
    }
}
