import SwiftUI
import AVFoundation

// MARK: - Settings you can change

/// Every wait must be longer than the iPad's Dwell time (about 2 seconds),
/// so a gaze that just stays put cannot select twice.
enum Timing {
    static let entryLock: TimeInterval = 3      // after TALK opens YES/NO, answers wait this long
    /// After an answer it stays lit and answers wait this long (0-10 s, set on the Settings screen).
    static var answerLock: TimeInterval { AppSettings.answerPause }
    static let idle: TimeInterval = 60          // YES/NO with no choice for this long goes back to TALK
    static let idleReturnLock: TimeInterval = 5 // after that, TALK waits this long
    static let pictureTime: TimeInterval = 15   // Training mode: a picture stays this long
}

struct AnswerChoice: Identifiable {
    let id: String
    let label: String
    let say: String
    let face: String
    let color: Color
}

/// Answer buttons, left to right. Version 2 (4 fields) = add entries here.
let answerChoices: [AnswerChoice] = [
    AnswerChoice(id: "yes", label: "YES", say: "Yes", face: "😊",
                 color: Color(red: 0.12, green: 0.62, blue: 0.33)),
    AnswerChoice(id: "no", label: "NO", say: "No", face: "☹️",
                 color: Color(red: 0.84, green: 0.23, blue: 0.23)),
]

enum Screen {
    case home
    case answer
    case settings
}

// MARK: - Behaviour

final class Controller: ObservableObject {
    @Published private(set) var screen: Screen = .home
    @Published private(set) var highlight: String? = nil
    @Published private(set) var locked = false

    // Training mode: YES and NO take turns; each choice shows a picture for 15 s. Silent.
    @Published private(set) var training = false
    @Published private(set) var trainingTurn = answerChoices[0].id   // always starts with YES
    @Published private(set) var picture: TrainingPicture? = nil

    private let speaker = Speaker()
    private let deck = PictureDeck()
    private var pictureWork: DispatchWorkItem?
    private var lockUntil = Date.distantPast
    private var unlockWork: DispatchWorkItem?
    private var idleWork: DispatchWorkItem?

    func select(_ target: String) {
        // EXIT always works: choosing it by accident only goes back to the safe TALK screen.
        if screen == .answer && target == "exit" {
            goHome()
            unlock()
            return
        }

        if Date() < lockUntil { return }

        if screen == .home {
            // He chooses himself: TALK = normal YES/NO (speaks), TRAINING = pictures (silent).
            switch target {
            case "talk":
                training = false
            case "training":
                // Only when the family switched it on AND the folder has pictures.
                guard AppSettings.trainingMode, deck.reload() > 0 else { return }
                training = true
            default:
                return
            }
            screen = .answer
            trainingTurn = answerChoices[0].id
            lock(for: Timing.entryLock, then: nil)
            if !training { restartIdle() }   // in Training mode it never goes back to TALK by itself
            return
        }

        if training {
            showPicture(on: target)
            return
        }

        guard let answer = answerChoices.first(where: { $0.id == target }) else { return }
        speaker.say(answer.say)
        highlight = answer.id
        lock(for: Timing.answerLock, then: { [weak self] in self?.highlight = nil })
        restartIdle()
    }

    /// Settings opens only from the TALK screen, and only when the family holds the Settings button.
    func openSettings() {
        guard screen == .home else { return }
        screen = .settings
    }

    func closeSettings() {
        guard screen == .settings else { return }
        screen = .home
    }

    /// Training mode: only the button whose turn it is works, and only when no picture is showing.
    private func showPicture(on target: String) {
        guard picture == nil, target == trainingTurn,
              let index = answerChoices.firstIndex(where: { $0.id == target }),
              let image = deck.next() else { return }
        picture = TrainingPicture(on: target, image: image)
        pictureWork?.cancel()
        let nextTurn = answerChoices[(index + 1) % answerChoices.count].id
        let work = DispatchWorkItem { [weak self] in
            self?.picture = nil
            self?.trainingTurn = nextTurn
        }
        pictureWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Timing.pictureTime, execute: work)
    }

    private func lock(for seconds: TimeInterval, then afterUnlock: (() -> Void)?) {
        lockUntil = Date().addingTimeInterval(seconds)
        locked = true
        unlockWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.locked = false
            afterUnlock?()
        }
        unlockWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }

    private func unlock() {
        unlockWork?.cancel()
        unlockWork = nil
        lockUntil = Date.distantPast
        locked = false
    }

    private func restartIdle() {
        idleWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.goHome()
            self.lock(for: Timing.idleReturnLock, then: nil)
        }
        idleWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Timing.idle, execute: work)
    }

    private func goHome() {
        idleWork?.cancel()
        idleWork = nil
        pictureWork?.cancel()
        pictureWork = nil
        screen = .home
        highlight = nil
        picture = nil
        training = false
        trainingTurn = answerChoices[0].id
    }
}

// MARK: - Sound: spoken answers

final class Speaker {
    private let synthesizer = AVSpeechSynthesizer()

    init() {
        // .playback: sound plays even when the iPad is in Silent Mode.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [])
        try? session.setActive(true)
    }

    func say(_ text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }
}
