# Swift Human Guidelines

A comprehensive Claude Code skill for building production-ready Swift and SwiftUI applications across all Apple platforms.

## What This Skill Does

This skill provides Claude with deep knowledge of Swift/SwiftUI development best practices, enabling it to help you:

- **Build new apps from scratch** with proper architecture (MVVM), state management, and navigation patterns
- **Follow Apple Human Interface Guidelines** for iOS, iPadOS, macOS, watchOS, and tvOS
- **Write performant code** using lazy loading, proper state management, and async/await
- **Create cross-platform apps** that maximize code sharing while respecting platform conventions
- **Use modern Swift features** including concurrency, property wrappers, and generics

## Installation

```bash
npx skills add frostist/swift-human-guidelines
```

Or add the skill directory to your Claude Code skills path.

## When to Use

The skill activates automatically when working on:
- Swift code and SwiftUI views
- Xcode projects
- iOS, macOS, watchOS, or tvOS development
- App architecture and performance optimization

## Contents

### Reference Documentation

| File | Description |
|------|-------------|
| `references/human-interface-guidelines.md` | Apple HIG principles, platform-specific guidelines, typography, color, accessibility |
| `references/swiftui-best-practices.md` | MVVM architecture, state management, view composition, navigation, testing |
| `references/swift-language-features.md` | Property wrappers, async/await, actors, generics, memory management, Swift 6 |
| `references/performance-optimization.md` | View optimization, lazy loading, profiling with Instruments |
| `references/cross-platform-development.md` | Conditional compilation, shared code architecture, platform-specific UI |

### App Templates

| File | Description |
|------|-------------|
| `assets/ios-app-template.swift` | Production-ready iOS app with TabView, MVVM, async/await, authentication flow |
| `assets/macos-app-template.swift` | Production-ready macOS app with NavigationSplitView, Settings, toolbar, keyboard shortcuts |

## Quick Examples

**Ask Claude to:**
- "Create a new iOS app with tab navigation and a list that fetches data from an API"
- "Add a settings screen following Apple HIG"
- "Optimize this list view for better scrolling performance"
- "Make this view work on both iOS and macOS"
- "Implement proper state management for this feature"

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
- **Async/Await**: Modern concurrency for all async operations
- **Lazy Loading**: LazyVStack/LazyHStack for large collections

## License

MIT
