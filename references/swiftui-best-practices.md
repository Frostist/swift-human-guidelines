# SwiftUI Best Practices

## Table of Contents
- [Architecture Patterns](#architecture-patterns)
- [State Management](#state-management)
- [View Composition](#view-composition)
- [Navigation](#navigation)
- [Data Flow](#data-flow)
- [Modifiers and Styling](#modifiers-and-styling)
- [Testing](#testing)
- [Common Patterns](#common-patterns)

## Architecture Patterns

### MVVM (Model-View-ViewModel)

**Recommended pattern for SwiftUI apps**

```swift
// Model: Pure data structures
struct Article: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String
    let publishedAt: Date
}

// ViewModel: Business logic and state
@MainActor
class ArticleListViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let repository: ArticleRepository
    
    init(repository: ArticleRepository = .shared) {
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

// View: UI only
struct ArticleListView: View {
    @StateObject private var viewModel = ArticleListViewModel()
    
    var body: some View {
        List(viewModel.articles) { article in
            ArticleRow(article: article)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .task {
            await viewModel.loadArticles()
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        }
    }
}
```

### Repository Pattern

```swift
protocol ArticleRepository {
    func fetchArticles() async throws -> [Article]
    func fetchArticle(id: UUID) async throws -> Article
    func saveArticle(_ article: Article) async throws
}

class NetworkArticleRepository: ArticleRepository {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }
    
    func fetchArticles() async throws -> [Article] {
        try await networkService.request(endpoint: .articles)
    }
    
    func fetchArticle(id: UUID) async throws -> Article {
        try await networkService.request(endpoint: .article(id))
    }
    
    func saveArticle(_ article: Article) async throws {
        try await networkService.post(endpoint: .articles, body: article)
    }
}
```

## State Management

### Local State (@State)

Use for simple, view-local state

```swift
struct CounterView: View {
    @State private var count = 0
    
    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") { count += 1 }
        }
    }
}
```

### Shared State (@StateObject, @ObservedObject)

```swift
// Parent creates and owns
struct ParentView: View {
    @StateObject private var settings = AppSettings()
    
    var body: some View {
        ChildView(settings: settings)
    }
}

// Child observes
struct ChildView: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Toggle("Dark Mode", isOn: $settings.isDarkMode)
    }
}
```

### Environment State (@EnvironmentObject)

```swift
@main
struct MyApp: App {
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        if authManager.isAuthenticated {
            HomeView()
        } else {
            LoginView()
        }
    }
}
```

### Bindings (@Binding)

```swift
struct SettingsView: View {
    @State private var username = ""
    
    var body: some View {
        Form {
            UsernameField(username: $username)
        }
    }
}

struct UsernameField: View {
    @Binding var username: String
    
    var body: some View {
        TextField("Username", text: $username)
            .textInputAutocapitalization(.never)
    }
}
```

## View Composition

### Extract Subviews

```swift
// ❌ Bad: Monolithic view
struct ProfileView: View {
    let user: User
    
    var body: some View {
        VStack {
            AsyncImage(url: user.avatarURL) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            
            Text(user.name)
                .font(.title)
            
            Text(user.bio)
                .font(.body)
                .foregroundStyle(.secondary)
            
            HStack {
                VStack {
                    Text("\(user.followers)")
                    Text("Followers")
                }
                VStack {
                    Text("\(user.following)")
                    Text("Following")
                }
            }
        }
    }
}

// ✅ Good: Composed from smaller views
struct ProfileView: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 16) {
            ProfileAvatar(url: user.avatarURL)
            ProfileInfo(user: user)
            ProfileStats(user: user)
        }
    }
}

struct ProfileAvatar: View {
    let url: URL?
    
    var body: some View {
        AsyncImage(url: url) { image in
            image.resizable()
        } placeholder: {
            ProgressView()
        }
        .frame(width: 100, height: 100)
        .clipShape(Circle())
    }
}
```

### Use ViewBuilder

```swift
struct CardView<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// Usage
CardView(title: "Profile") {
    Text("Name: John")
    Text("Age: 30")
}
```

### Prefer Composition Over Inheritance

```swift
// ✅ Good: Protocol composition
protocol Loadable {
    var isLoading: Bool { get }
}

protocol Errorable {
    var error: Error? { get }
}

class ViewModel: ObservableObject, Loadable, Errorable {
    @Published var isLoading = false
    @Published var error: Error?
}
```

## Navigation

### NavigationStack (iOS 16+)

```swift
struct ContentView: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            List(items) { item in
                NavigationLink(value: item) {
                    Text(item.name)
                }
            }
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item)
            }
            .navigationTitle("Items")
        }
    }
}
```

### Programmatic Navigation

```swift
@Observable
class NavigationCoordinator {
    var path = NavigationPath()
    
    func navigateTo(_ destination: Destination) {
        path.append(destination)
    }
    
    func navigateBack() {
        path.removeLast()
    }
    
    func navigateToRoot() {
        path = NavigationPath()
    }
}

enum Destination: Hashable {
    case detail(Item)
    case settings
    case profile(User)
}
```

### Sheet Presentation

```swift
struct ContentView: View {
    @State private var showingSheet = false
    @State private var selectedItem: Item?
    
    var body: some View {
        Button("Show Sheet") {
            showingSheet = true
        }
        .sheet(isPresented: $showingSheet) {
            SheetView()
        }
        
        // Or with item
        List(items) { item in
            Button(item.name) {
                selectedItem = item
            }
        }
        .sheet(item: $selectedItem) { item in
            ItemDetailView(item: item)
        }
    }
}
```

## Data Flow

### Unidirectional Data Flow

```swift
// State flows down, events flow up
struct ParentView: View {
    @State private var items: [Item] = []
    
    var body: some View {
        ItemListView(
            items: items,
            onDelete: { item in
                items.removeAll { $0.id == item.id }
            }
        )
    }
}

struct ItemListView: View {
    let items: [Item]
    let onDelete: (Item) -> Void
    
    var body: some View {
        List(items) { item in
            ItemRow(item: item, onDelete: { onDelete(item) })
        }
    }
}
```

### Dependency Injection

```swift
// Protocol for testability
protocol DataService {
    func fetchData() async throws -> [Item]
}

class NetworkDataService: DataService {
    func fetchData() async throws -> [Item] {
        // Network implementation
    }
}

class MockDataService: DataService {
    func fetchData() async throws -> [Item] {
        // Mock data for testing
    }
}

// Inject dependency
struct ContentView: View {
    @StateObject private var viewModel: ViewModel
    
    init(dataService: DataService = NetworkDataService()) {
        _viewModel = StateObject(wrappedValue: ViewModel(dataService: dataService))
    }
    
    var body: some View {
        // View code
    }
}
```

## Modifiers and Styling

### Custom View Modifiers

```swift
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

// Usage
Text("Hello")
    .cardStyle()
```

### Conditional Modifiers

```swift
extension View {
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// Usage
Text("Hello")
    .if(isHighlighted) { view in
        view.foregroundStyle(.red)
    }
```

### Reusable Styles

```swift
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(configuration.isPressed ? Color.blue.opacity(0.8) : Color.blue)
            .foregroundStyle(.white)
            .cornerRadius(8)
    }
}

// Usage
Button("Submit") { }
    .buttonStyle(PrimaryButtonStyle())
```

## Testing

### Unit Testing ViewModels

```swift
@MainActor
class ArticleListViewModelTests: XCTestCase {
    func testLoadArticles() async throws {
        let mockRepo = MockArticleRepository()
        let viewModel = ArticleListViewModel(repository: mockRepo)
        
        await viewModel.loadArticles()
        
        XCTAssertEqual(viewModel.articles.count, 3)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
    
    func testLoadArticlesError() async throws {
        let mockRepo = MockArticleRepository(shouldFail: true)
        let viewModel = ArticleListViewModel(repository: mockRepo)
        
        await viewModel.loadArticles()
        
        XCTAssertTrue(viewModel.articles.isEmpty)
        XCTAssertNotNil(viewModel.error)
    }
}
```

### UI Testing with SwiftUI

```swift
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewDisplayName("Light Mode")
            
            ContentView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            ContentView()
                .previewDevice("iPhone SE (3rd generation)")
                .previewDisplayName("Small Device")
        }
    }
}
```

## Common Patterns

### Loading States

```swift
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case failed(Error)
}

class ViewModel: ObservableObject {
    @Published var state: LoadingState<[Item]> = .idle
    
    func load() async {
        state = .loading
        do {
            let items = try await fetchItems()
            state = .loaded(items)
        } catch {
            state = .failed(error)
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                Text("Tap to load")
            case .loading:
                ProgressView()
            case .loaded(let items):
                List(items) { item in
                    Text(item.name)
                }
            case .failed(let error):
                ErrorView(error: error)
            }
        }
        .task {
            await viewModel.load()
        }
    }
}
```

### Debouncing Search

```swift
struct SearchView: View {
    @State private var searchText = ""
    @State private var results: [Result] = []
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        List(results) { result in
            Text(result.title)
        }
        .searchable(text: $searchText)
        .onChange(of: searchText) { newValue in
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }
                results = await performSearch(newValue)
            }
        }
    }
}
```

### Pull to Refresh

```swift
struct ContentView: View {
    @State private var items: [Item] = []
    
    var body: some View {
        List(items) { item in
            Text(item.name)
        }
        .refreshable {
            await loadItems()
        }
    }
    
    func loadItems() async {
        items = await fetchItems()
    }
}
```

### Empty States

```swift
struct ContentView: View {
    let items: [Item]
    
    var body: some View {
        Group {
            if items.isEmpty {
                EmptyStateView()
            } else {
                List(items) { item in
                    ItemRow(item: item)
                }
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No Items")
                .font(.title2)
            Text("Add your first item to get started")
                .foregroundStyle(.secondary)
        }
    }
}
```

### Confirmation Dialogs

```swift
struct ContentView: View {
    @State private var showingConfirmation = false
    
    var body: some View {
        Button("Delete") {
            showingConfirmation = true
        }
        .confirmationDialog("Are you sure?", isPresented: $showingConfirmation) {
            Button("Delete", role: .destructive) {
                deleteItem()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}
```

### Preference Keys

```swift
struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ContentView: View {
    @State private var height: CGFloat = 0
    
    var body: some View {
        VStack {
            Text("Dynamic Height: \(height)")
            
            ScrollView {
                VStack {
                    ForEach(0..<10) { _ in
                        Text("Item")
                    }
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: HeightPreferenceKey.self,
                            value: geo.size.height
                        )
                    }
                )
            }
            .onPreferenceChange(HeightPreferenceKey.self) { value in
                height = value
            }
        }
    }
}
```

## iOS 18 & 26 Features

### SwiftUI/UIKit Animation Interoperability (iOS 18+)

**Documentation:** [What's new in SwiftUI - WWDC24](https://developer.apple.com/videos/play/wwdc2024/10144/)

You can now use SwiftUI Animation types to animate UIKit and AppKit views:

```swift
import SwiftUI
import UIKit

class ViewController: UIViewController {
    let animatableView = UIView()

    func animateWithSwiftUI() {
        // Use SwiftUI animation on UIKit view
        UIView.animate(.spring(duration: 0.5)) {
            self.animatableView.center = CGPoint(x: 200, y: 200)
            self.animatableView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }
    }

    func animateWithCustomSpring() {
        // Custom spring parameters
        UIView.animate(.spring(duration: 0.8, bounce: 0.3)) {
            self.animatableView.alpha = 0.5
        }
    }
}

// In SwiftUI, wrap UIKit views with consistent animations
struct HybridView: View {
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack {
            // SwiftUI view
            Circle()
                .fill(.blue)
                .scaleEffect(scale)

            // UIKit view with matching animation
            UIKitWrapper()
                .scaleEffect(scale)

            Button("Animate") {
                withAnimation(.spring(duration: 0.5)) {
                    scale = scale == 1.0 ? 1.5 : 1.0
                }
            }
        }
    }
}

struct UIKitWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .systemBlue
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
```

### Zoom Transition (iOS 18+)

**Documentation:** [What's new in UIKit - WWDC24](https://developer.apple.com/videos/play/wwdc2024/10118/)

New continuously interactive zoom transition for navigation and presentations:

```swift
struct ImageGalleryView: View {
    let images: [GalleryImage]
    @Namespace private var animation

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                    ForEach(images) { image in
                        NavigationLink(value: image) {
                            Image(image.name)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 150, height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .matchedGeometryEffect(
                                    id: image.id,
                                    in: animation
                                )
                        }
                    }
                }
            }
            .navigationDestination(for: GalleryImage.self) { image in
                ImageDetailView(image: image)
                    .navigationTransition(.zoom(
                        sourceID: image.id,
                        in: animation
                    ))
            }
        }
    }
}

struct ImageDetailView: View {
    let image: GalleryImage
    @Namespace private var animation

    var body: some View {
        GeometryReader { geometry in
            Image(image.name)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .matchedGeometryEffect(
                    id: image.id,
                    in: animation
                )
                // Supports interactive drag-to-dismiss
        }
        .ignoresSafeArea()
    }
}
```

### Unified Gesture System (iOS 18+)

**Documentation:** [What's new in SwiftUI - WWDC24](https://developer.apple.com/videos/play/wwdc2024/10144/)

Specify dependencies between gestures across SwiftUI and UIKit:

```swift
struct GesturePriorityView: View {
    @State private var dragOffset: CGSize = .zero
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Rectangle()
            .fill(.blue)
            .frame(width: 200, height: 200)
            .scaleEffect(scale)
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = value
                    }
            )
    }
}

// Gesture dependencies
struct DependentGesturesView: View {
    @State private var isPressing = false
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        Circle()
            .fill(isPressing ? .red : .blue)
            .frame(width: 100, height: 100)
            .offset(dragOffset)
            .gesture(
                LongPressGesture()
                    .onChanged { _ in isPressing = true }
                    .onEnded { _ in isPressing = false }
                    .sequenced(before: DragGesture())
                    .onChanged { value in
                        switch value {
                        case .second(true, let drag):
                            dragOffset = drag?.translation ?? .zero
                        default:
                            break
                        }
                    }
            )
    }
}
```

### UIKit/SwiftUI Scene Mixing (iOS 26+)

**Documentation:** [Make your UIKit app more flexible - WWDC25](https://developer.apple.com/videos/play/wwdc2025/282/)

Mix SwiftUI and UIKit scene types in a single app:

```swift
@main
struct HybridApp: App {
    var body: some Scene {
        // SwiftUI window
        WindowGroup {
            ContentView()
        }

        // UIKit window
        UIWindowScene { connectionOptions in
            let window = UIWindow()
            let viewController = LegacyViewController()
            window.rootViewController = viewController
            return window
        }
    }
}

// Or use SceneDelegate approach
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // Mix SwiftUI and UIKit in same scene
        let window = UIWindow(windowScene: windowScene)

        if shouldUseSwiftUI(for: session) {
            window.rootViewController = UIHostingController(
                rootView: ContentView()
            )
        } else {
            window.rootViewController = LegacyViewController()
        }

        self.window = window
        window.makeKeyAndVisible()
    }

    private func shouldUseSwiftUI(for session: UISceneSession) -> Bool {
        // Determine based on scene configuration
        return session.configuration.name == "SwiftUI Scene"
    }
}
```

### DocumentGroupLaunchScene (iOS 18+)

**Documentation:** [Evolve your document launch experience - WWDC24](https://developer.apple.com/videos/play/wwdc2024/10132/)

New launch experience for document-based apps:

```swift
@main
struct DocumentApp: App {
    var body: some Scene {
        DocumentGroupLaunchScene {
            // Browser view when no document open
            Text("Select or create a document")
                .font(.title)
        } editor: { configuration in
            // Editor view for opened document
            DocumentEditor(configuration: configuration)
        } background: {
            // Background content
            Color(.systemBackground)
        }
    }
}

struct DocumentEditor: View {
    let configuration: DocumentConfiguration<MyDocument>

    var body: some View {
        TextEditor(text: configuration.document.text)
            .navigationTitle(configuration.fileURL?.lastPathComponent ?? "Untitled")
    }
}
```

## Best Practices Summary

1. **MVVM architecture**: Separate concerns clearly
2. **Composition**: Build complex views from simple components
3. **Unidirectional data flow**: State down, events up
4. **Dependency injection**: Make code testable
5. **Proper state management**: Choose the right property wrapper
6. **Extract subviews**: Keep view bodies small and focused
7. **Custom modifiers**: Reuse styling logic
8. **Handle all states**: Loading, error, empty, success
9. **Async/await**: Use for all asynchronous operations
10. **Test ViewModels**: Unit test business logic thoroughly
