# Whisper Dictation

A macOS menu bar app for system-wide voice-to-text dictation powered by local Whisper inference. Hold a hotkey, speak, release — transcribed text is inserted at your cursor. Runs 100% offline on-device.

## Setup

```bash
git clone <repo-url>
cd desktop-dictate
./build.sh
open WhisperDictation.app
```

Requires macOS 14+ and Swift 5.9+ (Xcode Command Line Tools). First build takes 1-3 minutes (compiles whisper.cpp from source).
