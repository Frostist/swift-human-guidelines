# Swift Human Guidelines

A comprehensive Claude Code skill for building production-ready Swift 6 and SwiftUI applications across all Apple platforms, with full support for iOS 18, iOS 26, and Apple Intelligence features.

## What This Skill Does

This skill provides Claude with deep knowledge of Swift/SwiftUI development best practices, enabling it to help you:

- **Build new apps from scratch** with proper architecture (MVVM), state management, and navigation patterns
- **Follow Apple Human Interface Guidelines** including the Liquid Glass design system for iOS, iPadOS, macOS, watchOS, and tvOS
- **Implement Apple Intelligence features** using the Foundation Models API for on-device and cloud-based AI
- **Use Swift 6 features** including data-race safety, typed throws, and modern synchronization primitives
- **Implement iOS 26 background processing** with BGContinuedProcessingTask for long-running tasks
- **Add Call Translation API** for real-time audio translation in apps
- **Write performant code** using lazy loading, proper state management, and async/await
- **Create cross-platform apps** that maximize code sharing while respecting platform conventions

## Installation

```bash
npx skills add frostist/swift-human-guidelines
```

Or add the skill directory to your Claude Code skills path.

## When to Use

The skill activates automatically when working on:
- Swift 6 code and SwiftUI views
- Xcode projects
- iOS 18/26, iPadOS, macOS, watchOS, visionOS, or tvOS development
- Apple Intelligence and Foundation Models API integration
- Background processing and long-running tasks
- Translation features and Call Translation API
- App architecture, synchronization, and performance optimization

## Contents

### Reference Documentation

| File | Description |
|------|-------------|
| `references/human-interface-guidelines.md` | Apple HIG principles, Liquid Glass design system, platform-specific guidelines, typography, color, accessibility |
| `references/swiftui-best-practices.md` | MVVM architecture, state management, view composition, navigation, SwiftUI/UIKit interoperability, zoom transitions, testing |
| `references/swift-language-features.md` | Property wrappers, async/await, actors, generics, memory management, Swift 6 data-race safety, typed throws |
| `references/swift-synchronization.md` | Modern synchronization primitives (Mutex, Atomic), thread-safe code patterns, Sendable types |
| `references/foundation-models-api.md` | Apple Intelligence integration, on-device and cloud AI models, prompt engineering, function calling |
| `references/background-processing-ios26.md` | BGContinuedProcessingTask for long-running background operations, task management, best practices |
| `references/call-translation-api.md` | Real-time audio translation, language detection, translation UI patterns |
| `references/performance-optimization.md` | View optimization, lazy loading, profiling with Instruments |
| `references/cross-platform-development.md` | Conditional compilation, shared code architecture, platform-specific UI |

### App Templates

| File | Description |
|------|-------------|
| `assets/ios-app-template.swift` | Production-ready iOS app with TabView, MVVM, async/await, authentication flow |
| `assets/macos-app-template.swift` | Production-ready macOS app with NavigationSplitView, Settings, toolbar, keyboard shortcuts |

## New in iOS 18 & 26

### Apple Intelligence & Foundation Models
- On-device and cloud-based AI model integration
- Function calling and structured outputs
- Prompt engineering best practices
- Privacy-first AI implementation

### Background Processing (iOS 26)
- `BGContinuedProcessingTask` for long-running operations
- Extended background execution beyond typical limits
- Progress reporting and task management
- Power and thermal state handling

### Call Translation API
- Real-time audio translation during calls
- Automatic language detection
- Translation UI patterns and user experience
- Privacy and permission handling

### Swift 6 Enhancements
- Complete data-race safety at compile time
- Typed throws for better error handling
- Modern synchronization primitives (Mutex, Atomic)
- Enhanced actor isolation and Sendable types

### Design System Updates
- Liquid Glass design language
- Enhanced zoom transitions
- Improved SwiftUI/UIKit interoperability
- Document-based app patterns

## Quick Examples

**Ask Claude to:**
- "Create a new iOS 26 app with tab navigation and Apple Intelligence features"
- "Implement the Foundation Models API to summarize user content"
- "Add background processing with BGContinuedProcessingTask for data sync"
- "Integrate the Call Translation API for real-time translation"
- "Add a settings screen following Apple HIG and Liquid Glass design"
- "Optimize this list view for better scrolling performance"
- "Make this view work on both iOS and macOS"
- "Implement thread-safe code using Swift 6 synchronization primitives"
- "Add proper error handling with Swift 6 typed throws"

## Code Sharing Strategy

The skill teaches Claude to maximize code sharing across platforms:

```
100% shared  →  Models, business logic, networking
 95% shared  →  ViewModels, repositories, services
 70% shared  →  Reusable view components
Platform-specific  →  Navigation, window management
```

## Key Patterns

- **MVVM Architecture**: Models, Views, ViewModels with clear separation
- **Unidirectional Data Flow**: State flows down, events flow up
- **Dependency Injection**: Protocol-based for testability
- **Swift 6 Concurrency**: Async/await, actors, complete data-race safety
- **Modern Synchronization**: Mutex and Atomic for thread-safe state
- **Typed Error Handling**: Swift 6 typed throws for better error management
- **Lazy Loading**: LazyVStack/LazyHStack for large collections
- **Apple Intelligence**: Foundation Models API for on-device and cloud AI

## License

MIT
