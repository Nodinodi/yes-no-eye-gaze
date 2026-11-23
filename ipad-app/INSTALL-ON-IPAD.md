# Put the YES / NO app on the iPad (no computer, no internet needed afterwards)

The app is the folder **`YES NO.swiftpm`** (also packed as **`YES NO.swiftpm.zip`**).
It opens in Apple's free **Swift Playgrounds** app and runs on the iPad itself.

## 1. Install Swift Playgrounds (once)

App Store → search **Swift Playgrounds** (by Apple, free) → Get.

## 2. Copy the app to the iPad

Copy **`YES NO.swiftpm.zip`** from this folder to the iPad, any way you like, for example:
- a **USB stick**: copy the zip onto it on the computer, plug it into the iPad
  (USB-C iPads directly; older iPads need Apple's Lightning-to-USB adapter);
- or however you normally move files to the iPad.

On the iPad, open the **Files** app, find the zip and **tap it once**: it unpacks into a
folder called **`YES NO`** (or `YES NO.swiftpm`). Move it to **On My iPad** if you like.

## 3. Open it in Swift Playgrounds

- In **Files**, tap the **YES NO** app folder: it opens in Swift Playgrounds.
- If it does not open: open **Swift Playgrounds**, tap **Locations** / the folder icon,
  go to where you put it, and tap it.

## 4. Run it

- Tap the **▶ (Run)** button. The app appears on the right.
- Make the app fill the screen: drag the divider to the left, or tap the
  **full-screen / expand** button on the app side, so the code is hidden.
- The first time, if the iPad asks about sound or anything else, answer **Allow**.

## 5. Set up Eye Tracking and lock the iPad to the app

Follow **`SET-UP-IPAD.html`** (in this same folder, double-click it on the computer to read it):
Eye Tracking on, Dwell about **2 seconds**, Snap to Item **off**, Hot Corners **None**,
Auto-Lock **Never**, then **Guided Access** so his eyes can only press buttons inside the app.

The app itself keeps the screen awake and plays sound even in Silent Mode.

## How it works

- **TALK** (top middle): look and hold → the YES/NO screen opens.
- Ask your question straight away: the buttons are dimmed for 3 seconds.
- **YES** / **NO**: the iPad says "Yes" / "No", the choice lights up, and after 3 seconds
  he can answer the next question. It stays on YES/NO.
- **EXIT** (bottom): back to TALK, works at any time.
- No answer for 60 seconds → back to TALK by itself.
- **Settings** (small grey button, bottom right of TALK): **touch and hold 1 second** to open
  (a short tap or a Dwell look does nothing). Pause between answers (0–10 s) and the TRAINING button + picture folder.
- **🖼️ TRAINING** (purple, top right of TALK, when switched on in Settings): he starts practice
  himself. YES and NO take turns: each choice shows a random picture in that button's place
  for 15 seconds. Silent, always starts with YES, EXIT always works. Details in `SET-UP-IPAD.html`.

## If something goes wrong

- **Red error marks in the code** in Swift Playgrounds: take a screenshot and send it to Claude.
- **No voice**: turn the volume up. The voice is the iPad's own English voice, built in.
- **Change times or answers**: `Logic.swift`, at the top (`Timing` and `answerChoices`).
