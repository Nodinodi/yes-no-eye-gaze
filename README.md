# YES / NO — answer with your eyes (iPad)

A free, simple iPad app for people who cannot speak or move their hands, but can move their eyes.
They look at **YES** or **NO**, and the iPad says the word out loud.

It uses the iPad's own **Eye Tracking** and **Dwell Control** (iPadOS 18 or newer): looking at a
button for about 2 seconds "taps" it. The app only needs big, calm buttons.

- **Free.** Runs in Apple's free **Swift Playgrounds** app. No account, no subscription.
- **No internet** needed to use it.
- Use it, change it, share it (MIT licence).

## Screens

- **TALK**: a calm, empty screen with one TALK button at the top. Looking around is safe.
- **YES / NO**: two big buttons (green YES 😊, red NO ☹️) and an EXIT strip at the bottom.
  The iPad says "Yes" or "No". After an answer it waits a few seconds, so one long look
  cannot answer twice. EXIT always works.
- **Settings** (small grey button on TALK, **touch and hold 1 second**, so the eyes cannot open it):
  - pause between answers, 0–10 seconds (default 3);
  - **Training mode**: practice with a reward. Choose a folder of pictures the person likes.
    YES and NO take turns; each choice shows a random picture in that button's place for
    15 seconds. Silent, always starts with YES.

## Put it on an iPad

1. Install **Swift Playgrounds** (App Store, free).
2. Copy [`ipad-app/YES NO.swiftpm.zip`](ipad-app/) to the iPad, tap it in the Files app, then tap the folder to open it in Swift Playgrounds and press ▶ Run.
3. Set up Eye Tracking, Dwell and Guided Access: see [`ipad-app/SET-UP-IPAD.html`](ipad-app/SET-UP-IPAD.html).

Full steps: [`ipad-app/INSTALL-ON-IPAD.md`](ipad-app/INSTALL-ON-IPAD.md).

## Change it

- Timings and answers: `ipad-app/YES NO.swiftpm/Logic.swift` (top: `Timing`, `answerChoices`).
- Layout: `ContentView.swift`. Settings: `Settings.swift`. Training pictures: `Training.swift`.

## Automatic test

Every change to the app is built and tapped through on an iPad simulator by GitHub Actions
(`.github/workflows/ipad-simulator.yml`). Screenshots and logs go to the `ci-results` branch.
A simulator has no camera, so Eye Tracking itself can only be tried on a real iPad.
