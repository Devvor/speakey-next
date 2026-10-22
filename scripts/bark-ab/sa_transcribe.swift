// sa_transcribe.swift
// Standalone SpeechAnalyzer CLI for the Bark A/B test — same API path the
// speakey app uses (SpeechTranscriber + AnalysisContext vocab biasing).
//
// Build/run on macOS 26 (Tahoe) with Xcode 26 toolchain:
//   swift sa_transcribe.swift clip.wav [--vocab vocab.txt] [--locale en-US]
//
// Prints the transcript to stdout, timing info to stderr.

import AVFoundation
import Foundation
import Speech

@main
struct SaTranscribe {
    static func main() async {
        let args = CommandLine.arguments.dropFirst()
        guard let audioPath = args.first(where: { !$0.hasPrefix("--") }) else {
            FileHandle.standardError.write("usage: swift sa_transcribe.swift <audio> [--vocab file] [--locale id]\n".data(using: .utf8)!)
            exit(2)
        }

        func option(_ name: String) -> String? {
            guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
            return args[i + 1]
        }
        let localeID = option("--locale") ?? "en-US"
        let vocabPath = option("--vocab")

        var vocabulary: [String] = []
        if let vocabPath {
            if let text = try? String(contentsOfFile: vocabPath, encoding: .utf8) {
                vocabulary = text
                    .split { $0 == "," || $0.isNewline }
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            }
        }

        guard SpeechTranscriber.isAvailable else {
            FileHandle.standardError.write("SpeechTranscriber unavailable (needs macOS 26 on supported hardware)\n".data(using: .utf8)!)
            exit(1)
        }

        do {
            let supported = await SpeechTranscriber.supportedLocales
            let locale = supported.first { $0.identifier(.bcp47) == localeID }
                ?? supported.first { $0.language.languageCode?.identifier == "en" }
                ?? supported[0]

            let transcriber = SpeechTranscriber(
                locale: locale,
                transcriptionOptions: [],
                reportingOptions: [],
                attributeOptions: []
            )

            // Install model assets if missing (same as the app).
            let installed = await SpeechTranscriber.installedLocales
            if !installed.contains(where: { $0.identifier(.bcp47) == locale.identifier(.bcp47) }) {
                if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
                    try await request.downloadAndInstall()
                }
            }

            let analyzer = SpeechAnalyzer(modules: [transcriber])
            if !vocabulary.isEmpty {
                let context = AnalysisContext()
                context.contextualStrings[.general] = vocabulary
                // Vocab biasing is best-effort, exactly like the app.
                try? await analyzer.setContext(context)
            }

            let resultsTask = Task<String, Error> {
                var transcript = AttributedString("")
                for try await result in transcriber.results {
                    transcript += result.text
                }
                return String(transcript.characters)
            }

            let fileURL = URL(fileURLWithPath: audioPath)
            let audioFile = try AVAudioFile(forReading: fileURL)
            let duration = Double(audioFile.length) / max(audioFile.processingFormat.sampleRate, 1)

            let start = Date()
            guard let lastSampleTime = try await analyzer.analyzeSequence(from: audioFile) else {
                FileHandle.standardError.write("no audio samples\n".data(using: .utf8)!)
                exit(1)
            }
            try await analyzer.finalizeAndFinish(through: lastSampleTime)
            let transcript = try await withThrowingTaskGroup(of: String.self) { group in
                group.addTask { try await resultsTask.value }
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(max(30.0, duration + 30.0) * 1_000_000_000))
                    throw SpeechAnalyzerServiceTimeout()
                }
                guard let winner = try await group.next() else { throw SpeechAnalyzerServiceTimeout() }
                group.cancelAll()
                return winner
            }
            let elapsed = Date().timeIntervalSince(start)

            print(transcript.trimmingCharacters(in: .whitespacesAndNewlines))
            FileHandle.standardError.write(
                String(format: "sa_seconds %.3f audio_seconds %.2f locale %@ vocab_terms %d\n",
                       elapsed, duration, locale.identifier(.bcp47), vocabulary.count)
                    .data(using: .utf8)!
            )
        } catch {
            FileHandle.standardError.write("error: \(error.localizedDescription)\n".data(using: .utf8)!)
            exit(1)
        }
    }
}

struct SpeechAnalyzerServiceTimeout: Error {}
