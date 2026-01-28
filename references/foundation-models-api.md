# Foundation Models Framework (iOS 26+)

**Available:** iOS 26.0+, iPadOS 26.0+, macOS Tahoe+
**Documentation:** [iOS 26 Release Notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-26-release-notes)

## Overview

The Foundation Models framework provides access to the on-device models that power Apple Intelligence features. This framework enables any app to leverage Apple's machine learning capabilities for text extraction, summarization, and intelligent content processing—all while maintaining user privacy through on-device processing.

## Key Features

- **On-device processing**: All model inference runs locally, protecting user privacy
- **Text extraction**: Extract structured information from unstructured text
- **Summarization**: Generate concise summaries of long-form content
- **Apple Intelligence integration**: Built on the same models powering system features
- **Optimized performance**: Hardware-accelerated on Apple Silicon

## When to Use Foundation Models

### Good Use Cases
- Summarizing long documents or articles
- Extracting key information from text (dates, names, locations)
- Content categorization and tagging
- Smart text suggestions
- Document analysis
- Email composition assistance

### When NOT to Use
- Real-time character-by-character processing (too slow)
- Simple string operations (use standard APIs)
- When you need custom ML models (use Core ML instead)
- Cloud-based processing requirements (models are on-device only)

## Basic Usage

### Text Summarization

```swift
import FoundationModels

@MainActor
class DocumentSummarizer: ObservableObject {
    @Published var summary: String = ""
    @Published var isProcessing = false

    func summarize(_ text: String) async throws {
        isProcessing = true
        defer { isProcessing = false }

        let request = TextSummarizationRequest(
            text: text,
            maxLength: 200,
            style: .concise
        )

        let model = FoundationModel.shared
        summary = try await model.process(request)
    }
}

// SwiftUI Usage
struct DocumentView: View {
    @StateObject private var summarizer = DocumentSummarizer()
    let documentText: String

    var body: some View {
        VStack {
            ScrollView {
                Text(documentText)
            }

            if summarizer.isProcessing {
                ProgressView("Summarizing...")
            } else if !summarizer.summary.isEmpty {
                VStack(alignment: .leading) {
                    Text("Summary")
                        .font(.headline)
                    Text(summarizer.summary)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(12)
            }
        }
        .task {
            try? await summarizer.summarize(documentText)
        }
    }
}
```

### Text Extraction

```swift
import FoundationModels

struct ContactInfo {
    let name: String?
    let email: String?
    let phone: String?
    let address: String?
}

class InfoExtractor {
    func extractContactInfo(from text: String) async throws -> ContactInfo {
        let request = TextExtractionRequest(
            text: text,
            entities: [.personName, .emailAddress, .phoneNumber, .postalAddress]
        )

        let model = FoundationModel.shared
        let result = try await model.process(request)

        return ContactInfo(
            name: result.entity(for: .personName)?.first,
            email: result.entity(for: .emailAddress)?.first,
            phone: result.entity(for: .phoneNumber)?.first,
            address: result.entity(for: .postalAddress)?.first
        )
    }
}
```

## Model Capabilities

### Available Request Types

```swift
// Text Summarization
TextSummarizationRequest(
    text: String,
    maxLength: Int = 150,
    style: SummaryStyle = .balanced
)

// Text Extraction
TextExtractionRequest(
    text: String,
    entities: [EntityType]
)

// Text Classification
TextClassificationRequest(
    text: String,
    categories: [String]
)

// Key Points Extraction
KeyPointsRequest(
    text: String,
    maxPoints: Int = 5
)
```

### Summary Styles

```swift
enum SummaryStyle {
    case concise      // Shortest summary, key facts only
    case balanced     // Default, good mix of detail and brevity
    case detailed     // Longer summary with more context
    case technical    // Preserves technical terms and details
}
```

### Entity Types

```swift
enum EntityType {
    case personName
    case organizationName
    case location
    case date
    case time
    case emailAddress
    case phoneNumber
    case url
    case postalAddress
    case number
    case currency
}
```

## Advanced Patterns

### Streaming Results

```swift
class StreamingSummarizer: ObservableObject {
    @Published var partialSummary: String = ""

    func summarizeWithStreaming(_ text: String) async throws {
        let request = TextSummarizationRequest(text: text)
        let model = FoundationModel.shared

        for try await chunk in model.processStreaming(request) {
            await MainActor.run {
                partialSummary += chunk
            }
        }
    }
}
```

### Batch Processing

```swift
func summarizeMultipleDocuments(_ documents: [String]) async throws -> [String] {
    let requests = documents.map { TextSummarizationRequest(text: $0) }
    let model = FoundationModel.shared

    return try await withThrowingTaskGroup(of: (Int, String).self) { group in
        for (index, request) in requests.enumerated() {
            group.addTask {
                let summary = try await model.process(request)
                return (index, summary)
            }
        }

        var summaries: [String?] = Array(repeating: nil, count: documents.count)
        for try await (index, summary) in group {
            summaries[index] = summary
        }

        return summaries.compactMap { $0 }
    }
}
```

### Custom Classification

```swift
class ContentClassifier {
    func classifyArticle(_ text: String) async throws -> ArticleCategory {
        let request = TextClassificationRequest(
            text: text,
            categories: ["Technology", "Business", "Science", "Sports", "Entertainment"]
        )

        let model = FoundationModel.shared
        let result = try await model.process(request)

        // Returns category with highest confidence
        return ArticleCategory(rawValue: result.topCategory) ?? .other
    }
}
```

## Performance Considerations

### Model Loading

Foundation Models are loaded on-demand and cached:

```swift
// First call: Model loads (~1-2 seconds)
let summary1 = try await model.process(request1)

// Subsequent calls: Uses cached model (fast)
let summary2 = try await model.process(request2)
```

### Processing Time Guidelines

| Input Length | Typical Processing Time |
|--------------|------------------------|
| < 500 words  | 0.5 - 1 second        |
| 500-2000 words | 1 - 3 seconds       |
| 2000-5000 words | 3 - 5 seconds      |
| > 5000 words | 5+ seconds            |

### Best Practices

```swift
// ✅ Good: Process in background
Task {
    let summary = try await model.process(request)
    await updateUI(with: summary)
}

// ✅ Good: Show progress for long operations
if text.count > 2000 {
    showProgressIndicator()
}

// ❌ Bad: Processing on main thread
let summary = try await model.process(request) // Blocks UI

// ✅ Good: Cache results
class SummaryCache {
    private var cache: [String: String] = [:]

    func summary(for text: String) async throws -> String {
        let key = text.hashValue.description
        if let cached = cache[key] {
            return cached
        }

        let summary = try await model.process(request)
        cache[key] = summary
        return summary
    }
}
```

## Privacy and Security

### On-Device Processing

All Foundation Models processing happens **entirely on-device**:
- No data sent to servers
- No network requests required
- Works offline
- Protected by device encryption

### User Data Handling

```swift
// ✅ Good: Respect user privacy
func processSensitiveDocument(_ text: String) async throws -> String {
    // Foundation Models never sends data off-device
    let summary = try await model.process(request)
    return summary
}

// Best practice: Still inform users
struct PrivacyNotice: View {
    var body: some View {
        Text("Document analysis happens privately on your device")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
```

## Error Handling

```swift
enum FoundationModelsError: Error {
    case modelUnavailable
    case textTooLong
    case insufficientMemory
    case processingFailed
    case unsupportedOperation
}

class RobustSummarizer {
    func summarize(_ text: String) async -> Result<String, Error> {
        do {
            // Validate input
            guard text.count <= 10_000 else {
                throw FoundationModelsError.textTooLong
            }

            let request = TextSummarizationRequest(text: text)
            let model = FoundationModel.shared
            let summary = try await model.process(request)

            return .success(summary)

        } catch FoundationModelsError.modelUnavailable {
            return .failure(FoundationModelsError.modelUnavailable)
        } catch FoundationModelsError.insufficientMemory {
            // Retry with shorter text
            let shortenedText = String(text.prefix(5000))
            return await summarize(shortenedText)
        } catch {
            return .failure(error)
        }
    }
}
```

## Platform Availability

### Device Requirements

Foundation Models requires:
- iOS 26.0+ / iPadOS 26.0+ / macOS Tahoe+
- Apple Silicon (M1 or newer) or A17 Pro or newer
- Minimum 4GB available memory

### Checking Availability

```swift
import FoundationModels

func checkModelAvailability() -> Bool {
    FoundationModel.isAvailable
}

// Show appropriate UI based on availability
struct AdaptiveFeatureView: View {
    var body: some View {
        if FoundationModel.isAvailable {
            SmartSummaryView()
        } else {
            ManualSummaryView()
        }
    }
}
```

## Integration with Apple Intelligence

Foundation Models is the same technology powering:
- Writing Tools system-wide
- Smart Reply in Messages
- Mail summaries
- Safari webpage summaries
- Notes intelligent features

Your app gets the same capabilities with consistent quality and performance.

## Xcode Integration

### Add Framework

```swift
// In your target's Build Phases > Link Binary With Libraries
// Add: FoundationModels.framework

// Import in Swift files
import FoundationModels
```

### Preview Support

```swift
#Preview {
    DocumentView(documentText: "Sample text...")
}

// Foundation Models works in Xcode Previews
```

## Testing

```swift
import XCTest
import FoundationModels

@MainActor
class SummarizerTests: XCTestCase {
    func testSummarization() async throws {
        let longText = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit...
        """ // 1000+ words

        let request = TextSummarizationRequest(
            text: longText,
            maxLength: 100
        )

        let model = FoundationModel.shared
        let summary = try await model.process(request)

        XCTAssertLessThanOrEqual(summary.count, 150)
        XCTAssertFalse(summary.isEmpty)
    }

    func testEntityExtraction() async throws {
        let text = "Contact John Doe at john@example.com or call 555-0123"

        let request = TextExtractionRequest(
            text: text,
            entities: [.personName, .emailAddress, .phoneNumber]
        )

        let model = FoundationModel.shared
        let result = try await model.process(request)

        XCTAssertEqual(result.entity(for: .personName)?.first, "John Doe")
        XCTAssertEqual(result.entity(for: .emailAddress)?.first, "john@example.com")
        XCTAssertEqual(result.entity(for: .phoneNumber)?.first, "555-0123")
    }
}
```

## Best Practices Summary

1. **Always process asynchronously**: Foundation Models can take several seconds
2. **Cache results**: Avoid reprocessing the same content
3. **Show progress indicators**: For operations > 1 second
4. **Handle errors gracefully**: Models may be unavailable
5. **Validate input length**: Stay under 10,000 words for best results
6. **Test on real devices**: Simulator performance differs significantly
7. **Respect user privacy**: On-device processing is a privacy feature—communicate this
8. **Provide fallbacks**: Not all devices support Foundation Models

## Resources

- [iOS 26 Release Notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-26-release-notes)
- [WWDC25: What's new in iOS 26](https://developer.apple.com/videos/wwdc2025/)
- [Foundation Models Framework Documentation](https://developer.apple.com/documentation/foundationmodels/)
- [Apple Intelligence Overview](https://developer.apple.com/apple-intelligence/)
