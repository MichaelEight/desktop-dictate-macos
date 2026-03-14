# Whisper Dictation

A macOS menu bar app for voice dictation anywhere on your system. Hold a hotkey, speak, and release to insert text at your cursor. It runs fully offline on your device with local Whisper transcription.

## Setup

```bash
git clone <repo-url>
cd desktop-dictate
./build.sh
open WhisperDictation.app
```

Requires macOS 14+ and Swift 5.9+ (Xcode Command Line Tools). First build takes 1-3 minutes (compiles whisper.cpp from source).

## Models

Downloaded on-demand from the app. Stored in `~/Library/Application Support/WhisperDictation/Models/`.

| Model | Size | Speed | Accuracy |
|-------|------|-------|----------|
| Tiny | 75 MB | Fastest | Basic |
| Base | 142 MB | Fast | Good |
| Small | 466 MB | Medium | Better |
| Medium | 1.5 GB | Slow | Great |
| Large V2 | 3.1 GB | Slowest | Best |
