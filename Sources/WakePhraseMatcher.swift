import Foundation

enum WakePhrase: String, Equatable {
    case heySpeakey
    case speakey

    var displayName: String {
        switch self {
        case .heySpeakey: return "Hey Speakey"
        case .speakey: return "Speakey"
        }
    }
}

struct WakePhraseMatch: Equatable {
    let phrase: WakePhrase
    let trailingText: String
}

/// Recognizes a wake phrase at the beginning of a live speech transcript.
///
/// Speech recognizers repeatedly publish increasingly complete versions of the
/// same utterance. `observe` therefore emits at most once until a non-matching
/// transcript is observed after the cooldown, or the caller explicitly rearms
/// the matcher for a new recognition session.
struct WakePhraseMatcher {
    var plainSpeakeyEnabled: Bool
    var cooldown: TimeInterval

    private var isArmed = true
    private var lastMatchDate: Date?

    init(plainSpeakeyEnabled: Bool = false, cooldown: TimeInterval = 1.0) {
        self.plainSpeakeyEnabled = plainSpeakeyEnabled
        self.cooldown = max(0, cooldown)
    }

    mutating func observe(_ transcript: String, at date: Date = Date()) -> WakePhraseMatch? {
        let detected = Self.detect(in: transcript, plainSpeakeyEnabled: plainSpeakeyEnabled)

        guard isArmed else {
            if detected == nil, cooldownHasElapsed(at: date) {
                isArmed = true
            }
            return nil
        }

        guard let detected else { return nil }
        isArmed = false
        lastMatchDate = date
        return detected
    }

    mutating func rearm() {
        isArmed = true
        lastMatchDate = nil
    }

    static func detect(
        in transcript: String,
        plainSpeakeyEnabled: Bool = false
    ) -> WakePhraseMatch? {
        if let match = match(pattern: heyPattern, phrase: .heySpeakey, in: transcript) {
            return match
        }
        // SpeechAnalyzer occasionally drops the quiet leading “Hey” while
        // still returning the distinctive segmented product name. Recover
        // only “mega phone” here; broader acoustic aliases stay Hey-gated.
        if let match = match(pattern: segmentedRecoveryPattern, phrase: .heySpeakey, in: transcript) {
            return match
        }
        guard plainSpeakeyEnabled else { return nil }
        return match(pattern: plainPattern, phrase: .speakey, in: transcript)
    }

    static let recognitionHints = [
        "Hey Speakey",
        "Speakey",
        "Hey Mega Phone",
        "Hey Make a Phone",
        "Hey Made a Phone",
        "Hey Mega Foam",
        "Hey Mega Form"
    ]

    private func cooldownHasElapsed(at date: Date) -> Bool {
        guard let lastMatchDate else { return true }
        return date.timeIntervalSince(lastMatchDate) >= cooldown
    }

    private static func match(
        pattern: NSRegularExpression,
        phrase: WakePhrase,
        in transcript: String
    ) -> WakePhraseMatch? {
        let range = NSRange(transcript.startIndex..<transcript.endIndex, in: transcript)
        guard let result = pattern.firstMatch(in: transcript, range: range),
              let matchedRange = Range(result.range, in: transcript) else {
            return nil
        }

        let trailing = transcript[matchedRange.upperBound...]
            .drop(while: { character in
                character.unicodeScalars.allSatisfy { trailingSeparators.contains($0) }
            })
        return WakePhraseMatch(phrase: phrase, trailingText: String(trailing))
    }

    private static let leadingSeparators = #"^[\s\p{P}\p{S}]*"#
    private static let phraseSeparator = #"[\s\p{P}\p{S}]+"#
    private static let phraseBoundary = #"(?=$|[\s\p{P}\p{S}])"#

    // Keep recognition aliases here rather than in SpeechAnalyzer's custom
    // vocabulary. Vocabulary hints should teach the correct product spelling;
    // these hidden aliases only recover common acoustic substitutions after
    // transcription. Fuzzy forms require the leading “Hey” phrase so enabling
    // the optional plain trigger cannot turn “make a phone call” into a command.
    private static let strictSpeakeyVariants = "(?:speakey|mega" + phraseSeparator + "phone)"
    private static let fuzzySpeakeyVariants = "(?:" + [
        strictSpeakeyVariants,
        "mega" + phraseSeparator + "fone",
        "mega" + phraseSeparator + "foam",
        "mega" + phraseSeparator + "form",
        "mega" + phraseSeparator + "phoned",
        "megafone",
        "megafoam",
        "megaform",
        "megha" + phraseSeparator + "phone",
        "mecca" + phraseSeparator + "phone",
        "mecha" + phraseSeparator + "phone",
        "meg" + phraseSeparator + "a" + phraseSeparator + "phone",
        "make" + phraseSeparator + "a" + phraseSeparator + "phone",
        "made" + phraseSeparator + "a" + phraseSeparator + "phone",
        "make" + phraseSeparator + "the" + phraseSeparator + "phone",
        "made" + phraseSeparator + "the" + phraseSeparator + "phone",
        "make" + phraseSeparator + "phone",
        "made" + phraseSeparator + "phone",
        "make" + phraseSeparator + "a" + phraseSeparator + "foam",
        "made" + phraseSeparator + "a" + phraseSeparator + "foam",
        "make" + phraseSeparator + "a" + phraseSeparator + "form",
        "made" + phraseSeparator + "a" + phraseSeparator + "form",
        "make" + phraseSeparator + "up" + phraseSeparator + "phone",
        "made" + phraseSeparator + "up" + phraseSeparator + "phone"
    ].joined(separator: "|") + ")"
    private static let heyVariants = "(?:hey|he|hay|hi)"

    private static let heyPattern = try! NSRegularExpression(
        pattern: leadingSeparators + heyVariants + phraseSeparator + fuzzySpeakeyVariants + phraseBoundary,
        options: [.caseInsensitive]
    )
    private static let plainPattern = try! NSRegularExpression(
        pattern: leadingSeparators + "speakey" + phraseBoundary,
        options: [.caseInsensitive]
    )
    private static let segmentedRecoveryPattern = try! NSRegularExpression(
        pattern: leadingSeparators + "mega" + phraseSeparator + "phone" + phraseBoundary,
        options: [.caseInsensitive]
    )
    private static let trailingSeparators = CharacterSet.whitespacesAndNewlines
        .union(.punctuationCharacters)
        .union(.symbols)
}
