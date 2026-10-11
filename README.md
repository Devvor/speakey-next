<p align="center">
  <img src="Resources/AppIcon-Source.png" width="128" height="128" alt="Speakey icon">
</p>

<h1 align="center">Speakey</h1>

<p align="center">
  A free, open-source dictation app for macOS that runs <b>entirely on your Mac</b>,<br>
  powered by Apple's SpeechAnalyzer and Foundation Models frameworks.
</p>

<p align="center">
  <sub>Requires macOS 26 (Tahoe) on Apple silicon</sub>
</p>

---

<div align="center">

Hold `Fn`, speak, and let go. Speakey types the result into whatever app you're using.

</div>

---

## Privacy: nothing leaves your Mac

Speakey has **no server, no network calls, no auto-updater, and no accounts**.

- Transcription runs entirely on-device via Apple's SpeechAnalyzer; audio never leaves your computer.
- Smart Cleanup runs on-device through Apple's Foundation Models framework, with a deterministic Basic fallback when Apple Intelligence is unavailable.
- **Recordings are not saved to disk** by default — dictation history stays in memory unless you opt in via Settings.
- The app makes **zero network requests**: no telemetry, no analytics, no update checks. Updates happen by rebuilding from source.

## Features

* **Fully on-device transcription** — Apple's speech model processes your audio directly on your Mac. No API key, no internet required.
* **Results as soon as you stop speaking** — Speakey streams audio into the analyzer while you're talking, so most of the work is done by the time you release the shortcut.
* **Hold-to-talk or toggle mode** — hold `Fn` to dictate, or press `Command-Fn` to start and stop recording. Shortcuts are configurable.
* **Smart on-device cleanup** — Apple's Foundation Models removes fillers, resolves self-corrections, and fixes punctuation without uploading your transcript.
* **Inline AI (Alpha)** — hold your dictation shortcut and begin with "Hey Speakey" to ask a question, generate text, or transform the sentence you just dictated.
* **A personal Dictionary** — add names and technical terms yourself, or let Speakey learn the words you use often. Ships with a seeded crypto/developer vocabulary, and merges a user-editable file at `~/Library/Application Support/Speakey/vocabulary.txt` on startup.
* **Multiple languages** — choose any language supported by Apple's on-device model.

## The transcription engine

SpeechAnalyzer is Apple's speech-to-text API introduced with macOS 26. It appears to use the same underlying technology as Apple's system dictation, and performs remarkably well:

| Engine                            | WER (clean) | WER (noisy) |
| --------------------------------- | ----------: | ----------: |
| **Apple SpeechAnalyzer**          |   **2.12%** |   **4.56%** |
| Whisper Small                     |       3.74% |       7.95% |
| Whisper Base                      |       5.42% |      12.51% |
| Apple SFSpeechRecognizer (legacy) |       9.02% |      16.25% |

<sub>Word error rate on LibriSpeech, measured by [Inscribe](https://get-inscribe.com/blog/apple-speech-api-benchmark.html) on an M2 Pro. Lower is better.</sub>

Because Speakey processes audio while you're speaking, there is usually very little left to do after you release `Fn`.

## Building from source

```bash
git clone https://github.com/Devvor/speakey-next
cd speakey-next
make        # requires Xcode 26 and the macOS 26 SDK
make run
```

Locally built apps skip Gatekeeper warnings entirely. See [CHANGES.md](CHANGES.md) for this fork's modifications.

## Credits

Speakey is based on [**Megaphone**](https://github.com/Kuberwastaken/megaphone) by [Kuber Mehta](https://github.com/Kuberwastaken) (MIT), which in turn builds on [**FreeFlow**](https://github.com/zachlatta/freeflow) by [Zach Latta](https://github.com/zachlatta) — including the `Fn` hold shortcut and original dictation surface.

This fork hardens the app for privacy and supply-chain safety: the auto-updater, all network calls, and on-disk recording retention were removed. Thanks to Kuber and Zach for building and open-sourcing the foundation.

## License

MIT — see [LICENSE](LICENSE).
