import SwiftUI

struct OptionList: View {
    let options: [String]
    @Binding var selection: String

    var body: some View {
        VStack(spacing: 12) {
            ForEach(options, id: \.self) { option in
                let selected = selection == option
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { selection = option }
                } label: {
                    HStack {
                        Text(option).font(.headline)
                        Spacer()
                        if selected {
                            Image(systemName: "checkmark.circle.fill").transition(.scale)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        selected
                        ? AnyShapeStyle(LinearGradient(colors: [.neonPink, .purple], startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(.ultraThinMaterial),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .scaleEffect(selected ? 1.03 : 1)
            }
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject var app: AppState
    @State private var step = 0
    @State private var name = ""
    @State private var vibe = ""
    @State private var reason = ""
    @State private var dream = ""
    @FocusState private var focused: Bool
    private let lastStep = 4

    private var canContinue: Bool {
        switch step {
        case 1: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return !vibe.isEmpty
        case 3: return !reason.isEmpty
        default: return true
        }
    }

    var body: some View {
        ZStack {
            AnimatedBackground()
            VStack(spacing: 0) {
                ProgressDots(count: lastStep + 1, index: step).padding(.top, 16)
                Spacer(minLength: 16)
                content
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)))
                Spacer(minLength: 16)
                Button(action: next) {
                    Text(step == 0 ? "Get started" : (step == lastStep ? "Let's go 🚀" : "Continue"))
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canContinue)
            }
            .padding(24)
        }
        .onChange(of: step) { _, new in focused = (new == 1 || new == 4) }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0:
            VStack(spacing: 20) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 90))
                    .foregroundStyle(LinearGradient(colors: [.neonPink, .neonCyan], startPoint: .top, endPoint: .bottom))
                    .symbolEffect(.bounce, options: .repeating)
                Text("LARP Location")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("Be anywhere in the world.\nWithout going anywhere.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.75))
            }
        case 1:
            question("First things first.\nWhat's your name?") {
                TextField("Your name", text: $name)
                    .focused($focused)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.next)
                    .onSubmit { if canContinue { next() } }
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding()
                    .glass(18)
            }
        case 2:
            question("What's your vibe, \(shortName)?") {
                OptionList(options: ["Mysterious 🕶️", "Main character ✨", "Chaotic 🔥", "Chill 🌴"], selection: $vibe)
            }
        case 3:
            question("Why are you LARPing?") {
                OptionList(options: ["Pranking friends 😈", "Flexing a vibe 😎", "Privacy 🕵️", "Just for fun 🎮"], selection: $reason)
            }
        default:
            question("Where do you wish you were right now?") {
                TextField("Paris, Tokyo, my bed…", text: $dream)
                    .focused($focused)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding()
                    .glass(18)
                Text("Optional. We won't judge.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private var shortName: String { name.trimmingCharacters(in: .whitespaces) }

    private func question<C: View>(_ title: String, @ViewBuilder _ body: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(title)
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            body()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func next() {
        focused = false
        if step < lastStep {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { step += 1 }
        } else {
            app.name = shortName
            app.vibe = vibe
            app.reason = reason
            app.dream = dream
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation { app.stage = 1 }
        }
    }
}
