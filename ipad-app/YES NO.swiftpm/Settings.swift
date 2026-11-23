import SwiftUI
import UniformTypeIdentifiers

// MARK: - Saved settings (kept when the app is closed)

enum SettingsKey {
    static let answerPause = "answerPause"            // seconds, 0...10
    static let trainingMode = "trainingMode"          // on / off
    static let trainingFolderName = "trainingFolderName"
    static let trainingFolderBookmark = "trainingFolderBookmark"
}

enum AppSettings {
    static let defaultAnswerPause: Double = 3
    static let pauseRange: ClosedRange<Double> = 0...10

    /// Pause after an answer before the next answer can be chosen.
    static var answerPause: TimeInterval {
        let saved = UserDefaults.standard.object(forKey: SettingsKey.answerPause) as? Double
        let value = saved ?? defaultAnswerPause
        return min(max(value, pauseRange.lowerBound), pauseRange.upperBound)
    }

    /// Training mode switch on the Settings screen.
    static var trainingMode: Bool {
        UserDefaults.standard.bool(forKey: SettingsKey.trainingMode)
    }
}

// MARK: - Settings screen (for the family, opened by holding the Settings button)

struct SettingsView: View {
    let size: CGSize
    let onDone: () -> Void

    @AppStorage(SettingsKey.answerPause) private var answerPause: Double = AppSettings.defaultAnswerPause
    @AppStorage(SettingsKey.trainingMode) private var trainingMode = false
    @AppStorage(SettingsKey.trainingFolderName) private var folderName = ""
    @AppStorage(SettingsKey.trainingFolderBookmark) private var folderBookmark = Data()
    @State private var pickingFolder = false
    @State private var pictureCount = 0

    /// Training mode needs a folder with pictures; until then Done cannot be pressed.
    private var canLeave: Bool { !trainingMode || pictureCount > 0 }

    private let talkBlue = Color(red: 0.18, green: 0.44, blue: 0.87)
    private let yesGreen = Color(red: 0.12, green: 0.62, blue: 0.33)
    private let card = Color(red: 0.16, green: 0.17, blue: 0.20)
    private let control = Color(red: 0.26, green: 0.28, blue: 0.33)
    private let hintGrey = Color(red: 0.63, green: 0.66, blue: 0.71)

    private var u: CGFloat { min(size.width, size.height) / 100 }

    var body: some View {
        VStack(spacing: 2.5 * u) {
            HStack {
                Text("⚙️ Settings")
                    .font(.system(size: 6 * u, weight: .heavy))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { if canLeave { onDone() } }) {
                    Text("Done")
                        .font(.system(size: 3.5 * u, weight: .bold))
                        .foregroundColor(canLeave ? .white : Color(red: 0.51, green: 0.53, blue: 0.58))
                        .padding(.horizontal, 4 * u)
                        .padding(.vertical, 1.5 * u)
                        .background(Capsule().fill(canLeave ? talkBlue : control))
                }
                .buttonStyle(.plain)
                .disabled(!canLeave)
                .accessibilityLabel("Done")
            }
            .padding(.top, 3 * u)

            pauseCard
            trainingCard
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4 * u)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { pictureCount = PictureFolder.pictureCount() }
        .fileImporter(isPresented: $pickingFolder, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result {
                saveFolder(url)
            }
        }
    }

    // MARK: Pause between answers

    private var pauseCard: some View {
        VStack(alignment: .leading, spacing: 1.5 * u) {
            Text("Pause between answers")
                .font(.system(size: 3.8 * u, weight: .bold))
                .foregroundColor(.white)
            Text("Wait time after an answer before the next answer can be chosen")
                .font(.system(size: 2.6 * u))
                .foregroundColor(hintGrey)

            HStack(spacing: 2 * u) {
                roundButton("−", label: "Shorter pause") { changePause(by: -1) }
                Slider(value: $answerPause, in: AppSettings.pauseRange, step: 1)
                    .tint(talkBlue)
                    .accessibilityLabel("Pause between answers")
                roundButton("+", label: "Longer pause") { changePause(by: 1) }
                Text("\(Int(answerPause)) sec")
                    .font(.system(size: 4.5 * u, weight: .heavy))
                    .foregroundColor(.white)
                    .frame(minWidth: 14 * u, alignment: .trailing)
                    .accessibilityIdentifier("pauseValue")
            }

            if answerPause < 3 {
                Text("Under 3 sec: one long look may choose an answer twice.")
                    .font(.system(size: 2.6 * u, weight: .semibold))
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 4 * u)
        .padding(.vertical, 3 * u)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 3 * u).fill(card))
    }

    private func changePause(by step: Double) {
        let next = answerPause + step
        answerPause = min(max(next, AppSettings.pauseRange.lowerBound), AppSettings.pauseRange.upperBound)
    }

    private func roundButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(symbol)
                .font(.system(size: 5 * u, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 8 * u, height: 8 * u)
                .background(Circle().fill(control))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: Training mode (switch + picture folder; the training itself is in Training.swift)

    private var trainingCard: some View {
        VStack(alignment: .leading, spacing: 2.2 * u) {
            HStack {
                VStack(alignment: .leading, spacing: 0.6 * u) {
                    Text("Training mode")
                        .font(.system(size: 3.8 * u, weight: .bold))
                        .foregroundColor(.white)
                    Text(trainingMode ? "On: pictures for 15 seconds, no sound" : "Off")
                        .font(.system(size: 2.6 * u))
                        .foregroundColor(hintGrey)
                }
                Spacer()
                Toggle("Training mode", isOn: $trainingMode)
                    .labelsHidden()
                    .tint(yesGreen)
            }

            if trainingMode {
                Divider().background(control)
                HStack(spacing: 2 * u) {
                    Button(action: { pickingFolder = true }) {
                        Text("📁 Choose folder")
                            .font(.system(size: 3 * u, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 3 * u)
                            .padding(.vertical, 1.3 * u)
                            .background(Capsule().fill(control))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Choose folder")

                    Text(folderName.isEmpty ? "No folder chosen" : "\(folderName): \(pictureCount) pictures")
                        .font(.system(size: 3 * u))
                        .foregroundColor(Color(red: 0.75, green: 0.77, blue: 0.81))
                        .lineLimit(1)
                }

                if !canLeave {
                    Text("Choose a folder with pictures, or turn Training mode off.")
                        .font(.system(size: 2.8 * u, weight: .bold))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.horizontal, 4 * u)
        .padding(.vertical, 3 * u)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 3 * u).fill(card))
    }

    /// Remember the chosen folder so the app can open it again later (after a restart too).
    private func saveFolder(_ url: URL) {
        let allowed = url.startAccessingSecurityScopedResource()
        defer { if allowed { url.stopAccessingSecurityScopedResource() } }
        if let bookmark = try? url.bookmarkData() {
            folderBookmark = bookmark
            folderName = url.lastPathComponent
        }
        pictureCount = PictureFolder.pictureCount()
    }
}
