import SwiftUI

struct ContentView: View {
    @StateObject private var controller = Controller()
    /// The family switches the TRAINING button on or off in Settings.
    @AppStorage(SettingsKey.trainingMode) private var trainingButtonOn = false

    private let background = Color(red: 0.11, green: 0.12, blue: 0.14)
    private let talkBlue = Color(red: 0.18, green: 0.44, blue: 0.87)
    private let exitGrey = Color(red: 0.29, green: 0.32, blue: 0.38)
    private let settingsGrey = Color(red: 0.20, green: 0.22, blue: 0.26)
    private let trainingPurple = Color(red: 0.49, green: 0.30, blue: 0.80)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                background.ignoresSafeArea()
                switch controller.screen {
                case .home:
                    homeScreen(size: geo.size)
                case .answer:
                    answerScreen(size: geo.size)
                case .settings:
                    SettingsView(size: geo.size, onDone: { controller.closeSettings() })
                }
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            // The user cannot wake a dark screen with the eyes: keep it on while the app is open.
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }

    /// 1% of the shorter screen side (like CSS "vmin").
    private func unit(_ size: CGSize) -> CGFloat {
        min(size.width, size.height) / 100
    }

    // MARK: TALK screen: calm empty space, TALK at the top (and TRAINING top right, if switched on)

    private func homeScreen(size: CGSize) -> some View {
        let u = unit(size)
        let landscape = size.width > size.height
        return ZStack(alignment: .topTrailing) {
            homeColumn(u: u)
            if trainingButtonOn {
                // Top right: when training opens, his resting eyes land on NO, which does nothing
                // at the start of training. Upright iPad: a bit lower, so it does not touch TALK.
                trainingButton(u: u)
                    .padding(.top, landscape ? 1.5 * u : 16 * u)
                    .padding(.trailing, 1.5 * u)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func trainingButton(u: CGFloat) -> some View {
        Button(action: { controller.select("training") }) {
            HStack(spacing: 1.5 * u) {
                Text("🖼️").font(.system(size: 6 * u))
                Text("TRAINING")
                    .font(.system(size: 4.6 * u, weight: .heavy))
                    .foregroundColor(.white)
            }
            .frame(width: 34 * u, height: 12 * u)
            .background(Capsule().fill(trainingPurple))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .opacity(controller.locked ? 0.55 : 1)
        .accessibilityLabel("Training")
    }

    private func homeColumn(u: CGFloat) -> some View {
        VStack(spacing: 0) {
            Button(action: { controller.select("talk") }) {
                HStack(spacing: 2.5 * u) {
                    Text("💬").font(.system(size: 8 * u))
                    Text("TALK")
                        .font(.system(size: 6 * u, weight: .heavy))
                        .foregroundColor(.white)
                }
                .frame(width: 38 * u, height: 12 * u)
                .background(Capsule().fill(talkBlue))
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .opacity(controller.locked ? 0.55 : 1)
            .accessibilityLabel("Talk")
            .padding(.top, 1.5 * u)

            Spacer(minLength: 0)

            HStack {
                Spacer()
                settingsButton(u: u)
            }
            .padding(.trailing, 2 * u)
            .padding(.bottom, 2 * u)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Small grey Settings button, bottom-right, far from TALK.
    /// It opens only when held for 1 second: a Dwell look makes a short tap, so the eyes cannot open it.
    private func settingsButton(u: CGFloat) -> some View {
        HStack(spacing: 1.2 * u) {
            Text("⚙️").font(.system(size: 4 * u))
            Text("Settings")
                .font(.system(size: 3 * u, weight: .bold))
                .foregroundColor(Color(red: 0.75, green: 0.77, blue: 0.81))
        }
        .padding(.horizontal, 2.5 * u)
        .frame(height: 7 * u)
        .background(Capsule().fill(settingsGrey))
        .contentShape(Capsule())
        .onLongPressGesture(minimumDuration: 1) { controller.openSettings() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Settings")
        .accessibilityHint("Hold for one second to open")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: YES / NO screen: answers from the top, EXIT strip at the bottom

    private func answerScreen(size: CGSize) -> some View {
        let u = unit(size)
        return VStack(spacing: 1 * u) {
            HStack(spacing: size.width * 0.02) {
                ForEach(answerChoices) { choice in
                    answerButton(choice, u: u)
                }
            }
            .padding(.horizontal, 1.5 * u)
            .padding(.top, 1.5 * u)

            Button(action: { controller.select("exit") }) {
                Text("⬆ EXIT")
                    .font(.system(size: 6 * u, weight: .heavy))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(RoundedRectangle(cornerRadius: 3 * u).fill(exitGrey))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Exit")
            .frame(height: size.height * 0.12)
            .padding(.horizontal, size.width * 0.12)
            .padding(.bottom, 1 * u)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func answerButton(_ choice: AnswerChoice, u: CGFloat) -> some View {
        let chosen = controller.highlight == choice.id
        let picture: UIImage? = controller.picture?.on == choice.id ? controller.picture?.image : nil
        let opacity: Double
        if controller.training {
            // Training: the picture is full; the button whose turn it is not is dimmed.
            if picture != nil {
                opacity = 1
            } else if controller.picture != nil || controller.trainingTurn != choice.id {
                opacity = 0.35
            } else if controller.locked {
                opacity = 0.55
            } else {
                opacity = 1
            }
        } else if controller.highlight != nil && !chosen {
            opacity = 0.35
        } else if controller.locked && !chosen {
            opacity = 0.55
        } else {
            opacity = 1
        }
        return Button(action: { controller.select(choice.id) }) {
            Group {
                if let picture = picture {
                    // The picture takes the place of the button, scaled to fit (nothing cut off).
                    Color.black
                        .overlay(Image(uiImage: picture).resizable().scaledToFit())
                        .clipShape(RoundedRectangle(cornerRadius: 4 * u))
                } else {
                    VStack(spacing: 2 * u) {
                        Text(choice.face).font(.system(size: 26 * u))
                        Text(choice.label)
                            .font(.system(size: 11 * u, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(RoundedRectangle(cornerRadius: 4 * u).fill(choice.color))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 4 * u)
                    .stroke(Color.white, lineWidth: chosen ? 2.2 * u : 0)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(opacity)
        .accessibilityLabel(choice.label)
        .accessibilityValue(picture != nil ? "Picture" : "")
    }
}
