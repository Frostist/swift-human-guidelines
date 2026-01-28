# SwiftUI Performance Optimization

## Table of Contents
- [View Performance](#view-performance)
- [State Management](#state-management)
- [List and Collection Performance](#list-and-collection-performance)
- [Memory Management](#memory-management)
- [Async Operations](#async-operations)
- [Build Performance](#build-performance)
- [Profiling Tools](#profiling-tools)

## View Performance

### Minimize View Updates

**Problem**: Unnecessary view body recalculations
**Solution**: Use proper state management and view identity

```swift
// ❌ Bad: Entire view rebuilds on any state change
struct ContentView: View {
    @State private var counter = 0
    @State private var text = ""
    
    var body: some View {
        VStack {
            Text("\(counter)")
            TextField("Enter text", text: $text)
            Button("Increment") { counter += 1 }
        }
    }
}

// ✅ Good: Separate concerns into child views
struct ContentView: View {
    var body: some View {
        VStack {
            CounterView()
            TextInputView()
        }
    }
}

struct CounterView: View {
    @State private var counter = 0
    var body: some View {
        VStack {
            Text("\(counter)")
            Button("Increment") { counter += 1 }
        }
    }
}
```

### Use @ViewBuilder Efficiently

```swift
// ❌ Bad: Creates unnecessary view hierarchy
var body: some View {
    VStack {
        if condition {
            Text("True")
        } else {
            Text("False")
        }
    }
}

// ✅ Good: Conditional content without extra containers
var body: some View {
    Group {
        if condition {
            Text("True")
        } else {
            Text("False")
        }
    }
}
```

### Avoid Expensive Computed Properties

```swift
// ❌ Bad: Computed on every body evaluation
var body: some View {
    let expensiveResult = performExpensiveCalculation()
    return Text(expensiveResult)
}

// ✅ Good: Cache expensive computations
@State private var cachedResult = ""

var body: some View {
    Text(cachedResult)
        .task {
            cachedResult = await performExpensiveCalculation()
        }
}
```

### Use Equatable for Complex Types

```swift
struct User: Equatable {
    let id: UUID
    let name: String
    let email: String
}

struct UserView: View {
    let user: User
    
    var body: some View {
        Text(user.name)
    }
}

// SwiftUI can now skip updates when user hasn't changed
```

## State Management

### Choose the Right Property Wrapper

**@State**: Local view state, value types
**@StateObject**: View owns the object lifecycle
**@ObservedObject**: View observes external object
**@EnvironmentObject**: Shared across view hierarchy
**@Binding**: Two-way connection to parent state

```swift
// ✅ Good: StateObject for view-owned data
struct ParentView: View {
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        ChildView(viewModel: viewModel)
    }
}

struct ChildView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        Text(viewModel.data)
    }
}
```

### Minimize Published Properties

```swift
// ❌ Bad: Every property publishes changes
class ViewModel: ObservableObject {
    @Published var name = ""
    @Published var age = 0
    @Published var email = ""
    @Published var phone = ""
}

// ✅ Good: Group related data, publish only what changes UI
class ViewModel: ObservableObject {
    @Published var userProfile: UserProfile
    private var internalCache: [String: Any] = [:]
}
```

### Use @Published Selectively

```swift
class DataManager: ObservableObject {
    @Published var items: [Item] = []
    
    // ❌ Bad: Triggers update even if items unchanged
    func refresh() {
        items = fetchItems()
    }
    
    // ✅ Good: Only update if data actually changed
    func refresh() {
        let newItems = fetchItems()
        if newItems != items {
            items = newItems
        }
    }
}
```

## List and Collection Performance

### Use LazyVStack/LazyHStack

```swift
// ❌ Bad: All views created immediately
ScrollView {
    VStack {
        ForEach(0..<1000) { i in
            RowView(index: i)
        }
    }
}

// ✅ Good: Views created on demand
ScrollView {
    LazyVStack {
        ForEach(0..<1000) { i in
            RowView(index: i)
        }
    }
}
```

### Provide Stable Identifiers

```swift
// ❌ Bad: Using index as ID
ForEach(Array(items.enumerated()), id: \.offset) { index, item in
    ItemView(item: item)
}

// ✅ Good: Using stable unique identifier
ForEach(items, id: \.id) { item in
    ItemView(item: item)
}

// ✅ Best: Item conforms to Identifiable
struct Item: Identifiable {
    let id: UUID
    let name: String
}

ForEach(items) { item in
    ItemView(item: item)
}
```

### Optimize List Row Views

```swift
// ❌ Bad: Complex view hierarchy in rows
struct RowView: View {
    let item: Item
    
    var body: some View {
        HStack {
            VStack {
                Text(item.title)
                Text(item.subtitle)
            }
            Spacer()
            Image(systemName: item.icon)
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

// ✅ Good: Simplified, efficient row
struct RowView: View {
    let item: Item
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                Text(item.subtitle)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: item.icon)
        }
        .padding()
    }
}
```

### Use onAppear Sparingly

```swift
// ❌ Bad: Heavy work in onAppear
List(items) { item in
    ItemView(item: item)
        .onAppear {
            loadRelatedData(for: item)
            updateAnalytics(item)
            prefetchImages(item)
        }
}

// ✅ Good: Batch operations, use task
List(items) { item in
    ItemView(item: item)
        .task {
            await loadEssentialData(for: item)
        }
}
```

## Memory Management

### Avoid Retain Cycles

```swift
// ❌ Bad: Strong reference cycle
class ViewModel: ObservableObject {
    var onUpdate: (() -> Void)?
    
    init() {
        onUpdate = {
            self.refresh() // Strong reference to self
        }
    }
}

// ✅ Good: Weak self capture
class ViewModel: ObservableObject {
    var onUpdate: (() -> Void)?
    
    init() {
        onUpdate = { [weak self] in
            self?.refresh()
        }
    }
}
```

### Release Resources Properly

```swift
struct VideoPlayerView: View {
    @StateObject private var player = VideoPlayer()
    
    var body: some View {
        PlayerView(player: player)
            .onDisappear {
                player.cleanup()
            }
    }
}

class VideoPlayer: ObservableObject {
    private var avPlayer: AVPlayer?
    
    func cleanup() {
        avPlayer?.pause()
        avPlayer = nil
    }
}
```

### Use Value Types When Possible

```swift
// ✅ Good: Value type for simple data
struct Settings {
    var theme: Theme
    var fontSize: CGFloat
    var notifications: Bool
}

// Only use class when needed
class NetworkManager: ObservableObject {
    @Published var isConnected = false
    // Shared state, reference semantics needed
}
```

## Async Operations

### Use Task Properly

```swift
// ❌ Bad: Blocking main thread
struct ContentView: View {
    @State private var data: [Item] = []
    
    var body: some View {
        List(data) { item in
            Text(item.name)
        }
        .onAppear {
            data = fetchData() // Blocks UI
        }
    }
}

// ✅ Good: Async task
struct ContentView: View {
    @State private var data: [Item] = []
    
    var body: some View {
        List(data) { item in
            Text(item.name)
        }
        .task {
            data = await fetchData()
        }
    }
}
```

### Cancel Tasks on Disappear

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
                if !Task.isCancelled {
                    results = await search(newValue)
                }
            }
        }
        .onDisappear {
            searchTask?.cancel()
        }
    }
}
```

### Use MainActor Appropriately

```swift
@MainActor
class ViewModel: ObservableObject {
    @Published var items: [Item] = []
    
    func loadData() async {
        // Already on main actor, safe to update @Published
        let data = await fetchFromNetwork()
        items = data
    }
}

// Or use explicit main actor calls
class DataManager: ObservableObject {
    @Published var items: [Item] = []
    
    func loadData() async {
        let data = await fetchFromNetwork()
        await MainActor.run {
            items = data
        }
    }
}
```

## Build Performance

### Reduce Type Checking Complexity

```swift
// ❌ Bad: Complex type inference
let result = items
    .filter { $0.isActive }
    .map { $0.name }
    .sorted()
    .joined(separator: ", ")

// ✅ Good: Explicit types help compiler
let activeItems: [Item] = items.filter { $0.isActive }
let names: [String] = activeItems.map { $0.name }
let sorted: [String] = names.sorted()
let result: String = sorted.joined(separator: ", ")
```

### Break Up Large View Bodies

```swift
// ❌ Bad: Massive view body
var body: some View {
    VStack {
        // 100+ lines of view code
    }
}

// ✅ Good: Extract subviews
var body: some View {
    VStack {
        headerSection
        contentSection
        footerSection
    }
}

private var headerSection: some View {
    // Header code
}
```

### Use Opaque Return Types

```swift
// ✅ Good: Opaque return type
var body: some View {
    Text("Hello")
}

// Avoid explicit types unless needed
var body: Text { // Less flexible
    Text("Hello")
}
```

## Profiling Tools

### Instruments
- **Time Profiler**: Identify CPU bottlenecks
- **Allocations**: Track memory usage
- **Leaks**: Find memory leaks
- **SwiftUI**: View body evaluation counts

### Xcode Debug Options
- **View Hierarchy Debugger**: Inspect view tree
- **Memory Graph**: Visualize object relationships
- **Gauges**: Real-time CPU, memory, disk, network

### SwiftUI Debugging
```swift
// Print when view body is evaluated
var body: some View {
    let _ = Self._printChanges()
    return Text("Hello")
}

// Identify view updates
struct ContentView: View {
    var body: some View {
        Text("Hello")
            .id(UUID()) // Force new identity (use sparingly)
    }
}
```

### Performance Testing
```swift
import XCTest

class PerformanceTests: XCTestCase {
    func testListScrolling() {
        measure {
            // Measure scrolling performance
        }
    }
    
    func testDataLoading() {
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Measure time and memory
        }
    }
}
```

## Best Practices Summary

1. **Minimize state**: Use local state, avoid global when possible
2. **Lazy loading**: Use lazy stacks for large lists
3. **Stable IDs**: Always use stable, unique identifiers
4. **Async/await**: Use for all network and heavy operations
5. **Value types**: Prefer structs over classes
6. **Weak references**: Avoid retain cycles in closures
7. **Profile regularly**: Use Instruments to find bottlenecks
8. **Test on device**: Simulator performance differs from real devices
9. **Reduce complexity**: Break up large views and functions
10. **Cache expensive operations**: Don't recalculate unnecessarily
