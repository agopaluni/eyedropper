# Eyedropper

A small menu bar color picker for macOS. Pick any pixel on screen and get its HEX code (copied to your clipboard automatically), plus RGB, HSL, HSB and SwiftUI values.

Requires macOS 14 Sonoma or later. Runs natively on both Apple silicon and Intel Macs.

## Install

### Option 1: one command (easiest)

Paste this into Terminal:

```bash
curl -fsSL https://github.com/agopaluni/eyedropper/releases/latest/download/Eyedropper.zip -o /tmp/Eyedropper.zip && ditto -x -k /tmp/Eyedropper.zip /Applications && open /Applications/Eyedropper.app
```

This downloads the latest release, unzips it into `/Applications`, and launches it. Look for the eyedropper icon in your menu bar.

### Option 2: download from Releases

1. Download `Eyedropper.zip` from the [latest release](https://github.com/agopaluni/eyedropper/releases/latest).
2. Unzip it and drag **Eyedropper.app** into **Applications**.
3. Open it. The app isn't notarized by Apple, so the first time macOS will say it can't verify the developer. Go to **System Settings → Privacy & Security**, scroll down, and click **Open Anyway**.
   You can also run this in Terminal instead:
   ```bash
   xattr -dr com.apple.quarantine /Applications/Eyedropper.app
   ```

### Option 3: build from source

You need the Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/agopaluni/eyedropper.git
cd eyedropper
./build.sh --install
```

## Use

- **Left-click** the menu bar icon to open the panel.
- **Right-click** the icon, or press **⌃⌥⌘C** from any app, to pick a color right away.
- After each pick, the HEX code is copied to your clipboard and briefly shown in the menu bar.
- Click any row in the panel to copy that format: HEX, `rgb()`, `hsl()`, `hsb()` or SwiftUI `Color(...)`.

## Features

- Picks with the system magnifier loupe, so it doesn't need Screen Recording permission.
- **Accurate hex codes:** colors are converted to sRGB, so codes match what browsers and design tools expect, even on P3 displays.
- **Contrast check:** shows the WCAG contrast ratio against white and black, with an AA/AAA grade.
- **Converter:** paste `#1A2B3C`, `1a2b3c`, `#abc` or `rgb(26, 43, 60)` to see every format.
- **Recent colors:** keeps your last 16. Click a swatch to load it, or right-click to copy or remove it.
- **Options:** uppercase or lowercase hex, with or without `#`, turn auto-copy off, launch at login.

## Uninstall

Quit it from the panel, then delete `/Applications/Eyedropper.app`.

## License

[MIT](LICENSE)
