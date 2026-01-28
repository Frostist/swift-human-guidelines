# Call Translation API (iOS 26+)

**Available:** iOS 26.0+, iPadOS 26.0+
**Documentation:** [iOS 26 What's New](https://developer.apple.com/ios/whats-new/)
**Framework:** Translation

## Overview

The Call Translation API enables real-time translation of voice conversations and audio content within your app. Built on the same technology powering FaceTime's Live Translation feature, this API provides automatic speech recognition, translation, and text-to-speech capabilities while maintaining user privacy through on-device processing.

## Key Features

- **Real-time translation**: Instant translation of spoken language
- **On-device processing**: Privacy-first, no server required
- **Multiple languages**: Support for 20+ language pairs
- **Bidirectional**: Translate both sides of a conversation
- **Audio and text output**: Get translations as text or synthesized speech
- **Low latency**: Optimized for conversational use

## Supported Languages

### iOS 26.0 Supported Pairs

**English** ↔ Spanish, French, German, Italian, Japanese, Korean, Mandarin Chinese, Portuguese, Russian, Arabic

**Spanish** ↔ English, French, Portuguese

**Mandarin Chinese** ↔ English, Japanese, Korean

Additional language pairs available through system updates.

### Checking Language Support

```swift
import Translation

func checkLanguageSupport(from source: Locale, to target: Locale) async -> Bool {
    await TranslationSession.isSupported(from: source.languageCode!, to: target.languageCode!)
}

// Example
let isSupported = await checkLanguageSupport(
    from: Locale(identifier: "en_US"),
    to: Locale(identifier: "es_ES")
)
```

## Basic Usage

### Simple Text Translation

```swift
import Translation

@MainActor
class Translator: ObservableObject {
    @Published var translatedText: String = ""
    @Published var isTranslating = false

    private var session: TranslationSession?

    func translate(_ text: String, from source: Locale, to target: Locale) async throws {
        isTranslating = true
        defer { isTranslating = false }

        let session = TranslationSession()
        self.session = session

        let request = TranslationRequest(
            sourceLanguage: source.languageCode!,
            targetLanguage: target.languageCode!,
            text: text
        )

        let response = try await session.translate(request)
        translatedText = response.translations.first?.translatedText ?? ""
    }
}

struct TranslationView: View {
    @StateObject private var translator = Translator()
    @State private var inputText = ""

    var body: some View {
        VStack {
            TextField("Enter text", text: $inputText)
                .textFieldStyle(.roundedBorder)

            Button("Translate to Spanish") {
                Task {
                    try? await translator.translate(
                        inputText,
                        from: Locale(identifier: "en"),
                        to: Locale(identifier: "es")
                    )
                }
            }
            .disabled(translator.isTranslating)

            if translator.isTranslating {
                ProgressView()
            } else {
                Text(translator.translatedText)
                    .padding()
            }
        }
        .padding()
    }
}
```

### Live Audio Translation

```swift
import Translation
import AVFoundation

@MainActor
class LiveTranslator: NSObject, ObservableObject {
    @Published var currentTranslation: String = ""
    @Published var isListening = false

    private var translationSession: TranslationSession?
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?

    func startLiveTranslation(from source: Locale, to target: Locale) throws {
        let session = TranslationSession()
        translationSession = session

        let audioEngine = AVAudioEngine()
        self.audioEngine = audioEngine

        let inputNode = audioEngine.inputNode
        self.inputNode = inputNode

        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            Task { @MainActor in
                await self?.processAudioBuffer(buffer, source: source, target: target)
            }
        }

        try audioEngine.start()
        isListening = true
    }

    func stopLiveTranslation() {
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        audioEngine = nil
        isListening = false
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, source: Locale, target: Locale) async {
        guard let session = translationSession else { return }

        do {
            let request = TranslationRequest(
                sourceLanguage: source.languageCode!,
                targetLanguage: target.languageCode!,
                audioBuffer: buffer
            )

            let response = try await session.translate(request)

            if let translation = response.translations.first {
                currentTranslation = translation.translatedText
            }
        } catch {
            print("Translation error: \(error)")
        }
    }
}
```

## Call Integration Example

```swift
import Translation
import CallKit

class TranslatedCallManager: NSObject, ObservableObject {
    @Published var translations: [CallTranslation] = []

    private var activeSession: TranslationSession?
    private let sourceLanguage = Locale(identifier: "en")
    private let targetLanguage = Locale(identifier: "es")

    func startCall(with contact: Contact) {
        let session = TranslationSession()
        activeSession = session

        // Configure for bidirectional translation
        session.configure(
            sourceLanguages: [sourceLanguage, targetLanguage],
            targetLanguages: [targetLanguage, sourceLanguage]
        )
    }

    func translateIncomingAudio(_ buffer: AVAudioPCMBuffer, speaker: CallParticipant) async {
        guard let session = activeSession else { return }

        do {
            let request = TranslationRequest(
                sourceLanguage: speaker.locale.languageCode!,
                targetLanguage: targetLanguageFor(speaker).languageCode!,
                audioBuffer: buffer
            )

            let response = try await session.translate(request)

            if let translated = response.translations.first {
                await MainActor.run {
                    translations.append(CallTranslation(
                        speaker: speaker,
                        originalText: response.recognizedText,
                        translatedText: translated.translatedText,
                        timestamp: Date()
                    ))
                }
            }
        } catch {
            print("Translation failed: \(error)")
        }
    }

    private func targetLanguageFor(_ speaker: CallParticipant) -> Locale {
        speaker.locale == sourceLanguage ? targetLanguage : sourceLanguage
    }

    func endCall() {
        activeSession?.invalidate()
        activeSession = nil
        translations.removeAll()
    }
}

struct CallTranslation: Identifiable {
    let id = UUID()
    let speaker: CallParticipant
    let originalText: String
    let translatedText: String
    let timestamp: Date
}
```

## Streaming Translation

For long-form content or conversations:

```swift
class StreamingTranslator: ObservableObject {
    @Published var partialTranslations: [String] = []

    private var session: TranslationSession?

    func startStreaming(from source: Locale, to target: Locale) {
        let session = TranslationSession()
        self.session = session

        session.configureStreaming(
            sourceLanguage: source.languageCode!,
            targetLanguage: target.languageCode!
        )
    }

    func translateStream(_ audioBuffer: AVAudioPCMBuffer) async throws {
        guard let session = session else { return }

        let stream = session.streamingTranslation(
            sourceLanguage: "en",
            targetLanguage: "es"
        )

        for try await partial in stream.translate(audioBuffer) {
            await MainActor.run {
                if let last = partialTranslations.last, partial.isFinal {
                    partialTranslations[partialTranslations.count - 1] = partial.text
                } else if !partial.isFinal {
                    partialTranslations.append(partial.text)
                }
            }
        }
    }
}
```

## UI Integration

### Translation Overlay

```swift
struct TranslatedCallView: View {
    @StateObject private var callManager = TranslatedCallManager()

    var body: some View {
        ZStack {
            // Call interface
            CallInterfaceView()

            // Translation overlay
            VStack {
                Spacer()

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(callManager.translations) { translation in
                            TranslationBubble(translation: translation)
                        }
                    }
                }
                .frame(maxHeight: 300)
                .background(.ultraThinMaterial)
            }
        }
    }
}

struct TranslationBubble: View {
    let translation: CallTranslation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(translation.speaker.name)
                    .font(.caption.bold())
                Spacer()
                Text(translation.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(translation.originalText)
                .font(.callout)
                .foregroundStyle(.secondary)

            Text(translation.translatedText)
                .font(.body)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
```

## Privacy and Permissions

### Required Permissions

**Info.plist:**
```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone to translate conversations.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>We need speech recognition to translate your conversations.</string>
```

### Privacy-First Design

```swift
class PrivacyAwareTranslator: ObservableObject {
    @Published var hasPermission = false

    func requestPermission() async {
        // Request microphone permission
        let micPermission = await AVCaptureDevice.requestAccess(for: .audio)

        // Request speech recognition permission
        let speechPermission = await SFSpeechRecognizer.requestAuthorization()

        await MainActor.run {
            hasPermission = micPermission && speechPermission == .authorized
        }
    }

    // All processing happens on-device
    func translate(_ audio: AVAudioPCMBuffer) async throws -> String {
        // No data sent to servers
        let session = TranslationSession()
        let response = try await session.translate(/* ... */)
        return response.translations.first?.translatedText ?? ""
    }
}
```

## Performance Optimization

### Model Preloading

```swift
class TranslationService {
    func preloadModels(for languages: [(source: Locale, target: Locale)]) async {
        for (source, target) in languages {
            // Download and cache models
            await TranslationSession.prepareModel(
                from: source.languageCode!,
                to: target.languageCode!
            )
        }
    }
}

// Call during app launch or idle time
Task {
    let service = TranslationService()
    await service.preloadModels(for: [
        (Locale(identifier: "en"), Locale(identifier: "es")),
        (Locale(identifier: "en"), Locale(identifier: "fr"))
    ])
}
```

### Battery Optimization

```swift
class EfficientTranslator: ObservableObject {
    private var session: TranslationSession?

    func configureForEfficiency() {
        session?.configure(
            mode: .balanced,  // .quality, .balanced, or .efficiency
            useGPU: false     // Disable for better battery life
        )
    }
}
```

## Error Handling

```swift
enum TranslationError: LocalizedError {
    case languagePairUnsupported
    case modelNotDownloaded
    case audioProcessingFailed
    case networkRequired

    var errorDescription: String? {
        switch self {
        case .languagePairUnsupported:
            return "This language pair is not supported."
        case .modelNotDownloaded:
            return "Translation model not available. Connect to Wi-Fi to download."
        case .audioProcessingFailed:
            return "Could not process audio input."
        case .networkRequired:
            return "Network connection required to download translation model."
        }
    }
}

class RobustTranslator {
    func translate(_ text: String, from source: Locale, to target: Locale) async throws -> String {
        // Check language support
        let isSupported = await TranslationSession.isSupported(
            from: source.languageCode!,
            to: target.languageCode!
        )

        guard isSupported else {
            throw TranslationError.languagePairUnsupported
        }

        // Check model availability
        let isAvailable = await TranslationSession.isModelAvailable(
            from: source.languageCode!,
            to: target.languageCode!
        )

        guard isAvailable else {
            throw TranslationError.modelNotDownloaded
        }

        // Perform translation
        let session = TranslationSession()
        let request = TranslationRequest(
            sourceLanguage: source.languageCode!,
            targetLanguage: target.languageCode!,
            text: text
        )

        let response = try await session.translate(request)
        return response.translations.first?.translatedText ?? ""
    }
}
```

## Best Practices

1. **Preload models**: Download translation models during setup or Wi-Fi connection
2. **Check support**: Verify language pair support before attempting translation
3. **Handle errors gracefully**: Provide fallback UI when translation unavailable
4. **Respect privacy**: Clearly communicate on-device processing
5. **Optimize battery**: Use balanced mode for real-time translation
6. **Test on device**: Simulator doesn't support audio processing
7. **Provide feedback**: Show visual indicators during translation
8. **Cache results**: Avoid retranslating the same content

## Resources

- [iOS 26 What's New](https://developer.apple.com/ios/whats-new/)
- [Translation Framework Documentation](https://developer.apple.com/documentation/translation)
- [Speech Recognition Guide](https://developer.apple.com/documentation/speech)
- [AVFoundation Audio Guide](https://developer.apple.com/documentation/avfoundation/audio)
