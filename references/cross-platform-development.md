# Cross-Platform Development with SwiftUI

## Table of Contents
- [Platform Detection](#platform-detection)
- [Conditional Compilation](#conditional-compilation)
- [Shared Code Architecture](#shared-code-architecture)
- [Platform-Specific UI](#platform-specific-ui)
- [Input Methods](#input-methods)
- [Navigation Patterns](#navigation-patterns)
- [Window Management](#window-management)

## Platform Detection

### Runtime Platform Checks

```swift
#if os(iOS)
// iOS-specific code
#elseif os(macOS)
// macOS-specific code
#elseif os(watchOS)
// watchOS-specific code
#elseif os(tvOS)
// tvOS-specific code
#endif

// Runtime checks
import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(iOS)
        iOSView()
        #elseif os(macOS)
        macOSView()
        #endif
    }
}
```

### Device Idiom Detection

```swift
#if os(iOS)
import UIKit

extension UIDevice {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}
#endif
```

### Environment Values

```swift
struct ContentView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        if horizontalSizeClass == .compact {
            CompactView()
        } else {
            RegularView()
        }
    }
}
```

## Conditional Compilation

### Target-Specific Code

```swift
struct AppConfig {
    #if os(iOS)
    static let defaultSpacing: CGFloat = 16
    static let cornerRadius: CGFloat = 12
    #elseif os(macOS)
    static let defaultSpacing: CGFloat = 20
    static let cornerRadius: CGFloat = 8
    #endif
}
```

### Feature Availability

```swift
@available(iOS 16.0, macOS 13.0, *)
struct ModernView: View {
    var body: some View {
        Text("Modern features")
            .fontDesign(.rounded)
    }
}

// Fallback for older versions
struct ContentView: View {
    var body: some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            ModernView()
        } else {
            LegacyView()
        }
    }
}
```

## Shared Code Architecture

### Model Layer (100% Shared)

```swift
// Models work across all platforms
struct Article: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String
    let author: String
    let publishedAt: Date
}

struct User: Identifiable, Codable {
    let id: UUID
    let name: String
    let email: String
    let avatarURL: URL?
}
```

### Business Logic Layer (100% Shared)

```swift
// ViewModels work across platforms
@MainActor
class ArticleListViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let repository: ArticleRepository
    
    init(repository: ArticleRepository = NetworkArticleRepository()) {
        self.repository = repository
    }
    
    func loadArticles() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            articles = try await repository.fetchArticles()
        } catch {
            self.error = error
        }
    }
}
```

### Repository Layer (95% Shared)

```swift
protocol ArticleRepository {
    func fetchArticles() async throws -> [Article]
    func saveArticle(_ article: Article) async throws
}

class NetworkArticleRepository: ArticleRepository {
    func fetchArticles() async throws -> [Article] {
        // Network code works on all platforms
        let url = URL(string: "https://api.example.com/articles")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Article].self, from: data)
    }
    
    func saveArticle(_ article: Article) async throws {
        // Shared implementation
    }
}
```

### View Layer (Platform-Specific)

```swift
// Shared view components
struct ArticleRow: View {
    let article: Article
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(article.title)
                .font(.headline)
            Text(article.author)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// Platform-specific containers
#if os(iOS)
struct ArticleListView: View {
    @StateObject private var viewModel = ArticleListViewModel()
    
    var body: some View {
        NavigationStack {
            List(viewModel.articles) { article in
                NavigationLink(value: article) {
                    ArticleRow(article: article)
                }
            }
            .navigationTitle("Articles")
            .navigationDestination(for: Article.self) { article in
                ArticleDetailView(article: article)
            }
        }
        .task {
            await viewModel.loadArticles()
        }
    }
}
#elseif os(macOS)
struct ArticleListView: View {
    @StateObject private var viewModel = ArticleListViewModel()
    @State private var selectedArticle: Article?
    
    var body: some View {
        NavigationSplitView {
            List(viewModel.articles, selection: $selectedArticle) { article in
                ArticleRow(article: article)
                    .tag(article)
            }
            .navigationTitle("Articles")
        } detail: {
            if let article = selectedArticle {
                ArticleDetailView(article: article)
            } else {
                Text("Select an article")
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            await viewModel.loadArticles()
        }
    }
}
#endif
```

## Platform-Specific UI

### Adaptive Layouts

```swift
struct AdaptiveView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        if horizontalSizeClass == .compact {
            // iPhone portrait, narrow iPad
            VStack {
                HeaderView()
                ContentView()
                FooterView()
            }
        } else {
            // iPad landscape, Mac
            HStack {
                SidebarView()
                VStack {
                    HeaderView()
                    ContentView()
                    FooterView()
                }
            }
        }
    }
}
```

### Platform-Specific Components

```swift
struct PlatformButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        #if os(iOS)
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .cornerRadius(12)
        }
        #elseif os(macOS)
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        #endif
    }
}
```

### Toolbar Adaptation

```swift
struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                // Content
            }
            .navigationTitle("Items")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") { }
                }
                #elseif os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button("Add") { }
                }
                ToolbarItem(placement: .automatic) {
                    Button("Refresh") { }
                }
                #endif
            }
        }
    }
}
```

## Input Methods

### Touch vs Pointer

```swift
struct InteractiveView: View {
    @State private var isHovered = false
    
    var body: some View {
        Text("Interactive")
            .padding()
            .background(isHovered ? Color.blue.opacity(0.2) : Color.clear)
            .cornerRadius(8)
            #if os(macOS)
            .onHover { hovering in
                isHovered = hovering
            }
            #endif
            .onTapGesture {
                handleTap()
            }
    }
}
```

### Keyboard Shortcuts

```swift
struct ContentView: View {
    var body: some View {
        Text("Content")
            #if os(macOS)
            .keyboardShortcut("n", modifiers: .command)
            #endif
    }
}

// App-level shortcuts
#if os(macOS)
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Custom Action") {
                    // Action
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
            }
        }
    }
}
#endif
```

### Context Menus

```swift
struct ItemView: View {
    let item: Item
    
    var body: some View {
        Text(item.name)
            .contextMenu {
                Button("Edit") { }
                Button("Duplicate") { }
                Divider()
                Button("Delete", role: .destructive) { }
            }
    }
}
```

## Navigation Patterns

### iOS Navigation

```swift
struct iOSApp: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            
            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
    }
}
```

### macOS Navigation

```swift
struct macOSApp: View {
    @State private var selectedItem: Item?
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $selectedItem) {
                Section("Library") {
                    Label("All Items", systemImage: "tray")
                    Label("Favorites", systemImage: "star")
                }
                
                Section("Collections") {
                    ForEach(collections) { collection in
                        Label(collection.name, systemImage: "folder")
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } detail: {
            // Detail view
            if let item = selectedItem {
                ItemDetailView(item: item)
            } else {
                Text("Select an item")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

### iPad Adaptive Navigation

```swift
struct iPadApp: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        if horizontalSizeClass == .compact {
            // Compact: Use tab bar like iPhone
            TabView {
                HomeView()
                    .tabItem { Label("Home", systemImage: "house") }
                SearchView()
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }
            }
        } else {
            // Regular: Use sidebar like Mac
            NavigationSplitView {
                SidebarView()
            } detail: {
                DetailView()
            }
        }
    }
}
```

## Window Management

### Multi-Window Support (iOS/iPadOS)

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(iOS)
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Window") {
                    // Request new window
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
        #endif
    }
}
```

### macOS Window Management

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            SidebarCommands()
            ToolbarCommands()
        }
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        
        Window("Inspector", id: "inspector") {
            InspectorView()
        }
        .keyboardShortcut("i", modifiers: [.command, .option])
        #endif
    }
}
```

## Best Practices

### Code Organization

```
MyApp/
├── Shared/
│   ├── Models/
│   │   ├── Article.swift
│   │   └── User.swift
│   ├── ViewModels/
│   │   ├── ArticleListViewModel.swift
│   │   └── UserProfileViewModel.swift
│   ├── Services/
│   │   ├── NetworkService.swift
│   │   └── DatabaseService.swift
│   └── Views/
│       └── Shared/
│           ├── ArticleRow.swift
│           └── UserAvatar.swift
├── iOS/
│   ├── Views/
│   │   ├── ArticleListView.swift
│   │   └── HomeView.swift
│   └── iOSApp.swift
├── macOS/
│   ├── Views/
│   │   ├── ArticleListView.swift
│   │   └── HomeView.swift
│   └── macOSApp.swift
└── watchOS/
    └── watchOSApp.swift
```

### Shared View Components

```swift
// Shared component that adapts
struct AdaptiveCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color(.systemBackground))
            #if os(iOS)
            .cornerRadius(12)
            .shadow(radius: 2)
            #elseif os(macOS)
            .cornerRadius(8)
            .shadow(radius: 1)
            #endif
    }
}
```

### Platform-Specific Extensions

```swift
extension View {
    #if os(iOS)
    func platformSpecificModifier() -> some View {
        self.navigationBarTitleDisplayMode(.large)
    }
    #elseif os(macOS)
    func platformSpecificModifier() -> some View {
        self.frame(minWidth: 300, minHeight: 400)
    }
    #endif
}
```

## Testing Cross-Platform Code

```swift
import XCTest

class CrossPlatformTests: XCTestCase {
    func testModelDecoding() throws {
        // Models work the same on all platforms
        let json = """
        {"id": "123", "name": "Test"}
        """
        let data = json.data(using: .utf8)!
        let item = try JSONDecoder().decode(Item.self, from: data)
        XCTAssertEqual(item.name, "Test")
    }
    
    @MainActor
    func testViewModel() async throws {
        let viewModel = ArticleListViewModel(
            repository: MockArticleRepository()
        )
        
        await viewModel.loadArticles()
        
        XCTAssertFalse(viewModel.articles.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }
}
```

## Summary

**Maximize code sharing:**
- 100% shared: Models, business logic, networking
- 95% shared: ViewModels, repositories, services
- 70% shared: Reusable view components
- Platform-specific: Navigation, window management, input handling

**Key principles:**
1. Use conditional compilation for platform differences
2. Design adaptive layouts with size classes
3. Extract shared components
4. Keep platform-specific code in separate files
5. Test shared code thoroughly
6. Respect platform conventions
