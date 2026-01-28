# Swift Language Features and Best Practices

## Table of Contents
- [Modern Swift Syntax](#modern-swift-syntax)
- [Concurrency](#concurrency)
- [Error Handling](#error-handling)
- [Optionals](#optionals)
- [Collections](#collections)
- [Protocols and Generics](#protocols-and-generics)
- [Memory Management](#memory-management)
- [Swift 6 Features](#swift-6-features)

## Modern Swift Syntax

### Property Wrappers

```swift
// Custom property wrapper
@propertyWrapper
struct Clamped<Value: Comparable> {
    private var value: Value
    private let range: ClosedRange<Value>
    
    var wrappedValue: Value {
        get { value }
        set { value = min(max(newValue, range.lowerBound), range.upperBound) }
    }
    
    init(wrappedValue: Value, _ range: ClosedRange<Value>) {
        self.range = range
        self.value = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }
}

struct Settings {
    @Clamped(0...100) var volume = 50
    @Clamped(0...1) var brightness = 0.8
}
```

### Result Builders

```swift
@resultBuilder
struct ArrayBuilder<Element> {
    static func buildBlock(_ components: Element...) -> [Element] {
        components
    }
    
    static func buildOptional(_ component: [Element]?) -> [Element] {
        component ?? []
    }
    
    static func buildEither(first component: [Element]) -> [Element] {
        component
    }
    
    static func buildEither(second component: [Element]) -> [Element] {
        component
    }
}

func makeArray<T>(@ArrayBuilder<T> builder: () -> [T]) -> [T] {
    builder()
}

let numbers = makeArray {
    1
    2
    if condition {
        3
    }
    4
}
```

### Opaque Types

```swift
// ✅ Good: Opaque return type
func makeView() -> some View {
    Text("Hello")
}

// Allows implementation flexibility
protocol Shape {
    func draw() -> String
}

func makeShape() -> some Shape {
    Circle() // Can change implementation without breaking API
}
```

### Type Inference

```swift
// ✅ Good: Let Swift infer types when obvious
let name = "John"
let age = 30
let items = [1, 2, 3]

// ✅ Good: Be explicit when needed for clarity
let temperature: Double = 98.6
let callback: (String) -> Void = { print($0) }
```

## Concurrency

### Async/Await

```swift
// Basic async function
func fetchUser(id: String) async throws -> User {
    let url = URL(string: "https://api.example.com/users/\(id)")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(User.self, from: data)
}

// Calling async functions
Task {
    do {
        let user = try await fetchUser(id: "123")
        print(user.name)
    } catch {
        print("Error: \(error)")
    }
}
```

### Structured Concurrency

```swift
// Parallel execution with async let
func loadDashboard() async throws -> Dashboard {
    async let user = fetchUser()
    async let posts = fetchPosts()
    async let notifications = fetchNotifications()
    
    return try await Dashboard(
        user: user,
        posts: posts,
        notifications: notifications
    )
}

// Task groups for dynamic parallelism
func fetchAllUsers(ids: [String]) async throws -> [User] {
    try await withThrowingTaskGroup(of: User.self) { group in
        for id in ids {
            group.addTask {
                try await fetchUser(id: id)
            }
        }
        
        var users: [User] = []
        for try await user in group {
            users.append(user)
        }
        return users
    }
}
```

### Actors

```swift
actor DatabaseManager {
    private var cache: [String: Data] = [:]
    
    func getData(key: String) async -> Data? {
        if let cached = cache[key] {
            return cached
        }
        
        let data = await fetchFromDisk(key: key)
        cache[key] = data
        return data
    }
    
    func setData(_ data: Data, key: String) {
        cache[key] = data
    }
    
    private func fetchFromDisk(key: String) async -> Data? {
        // Disk I/O
    }
}

// Usage
let db = DatabaseManager()
let data = await db.getData(key: "user_123")
```

### MainActor

```swift
@MainActor
class ViewModel: ObservableObject {
    @Published var items: [Item] = []
    
    func loadItems() async {
        // Already on main actor
        let newItems = await fetchItems()
        items = newItems // Safe to update @Published
    }
}

// Isolated functions
@MainActor
func updateUI() {
    // Guaranteed to run on main thread
}

// Non-isolated async context
func backgroundWork() async {
    let data = await fetchData()
    await MainActor.run {
        updateUI(with: data)
    }
}
```

### Task Management

```swift
// Detached tasks
Task.detached {
    // Runs independently, doesn't inherit context
    await heavyComputation()
}

// Task cancellation
let task = Task {
    for i in 1...100 {
        try Task.checkCancellation()
        await processItem(i)
    }
}

// Cancel after delay
Task {
    try await Task.sleep(nanoseconds: 5_000_000_000)
    task.cancel()
}

// Cooperative cancellation
func longRunningTask() async throws {
    for item in items {
        guard !Task.isCancelled else {
            throw CancellationError()
        }
        await process(item)
    }
}
```

## Error Handling

### Throwing Functions

```swift
enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingFailed
    case serverError(Int)
}

func fetchData(from urlString: String) throws -> Data {
    guard let url = URL(string: urlString) else {
        throw NetworkError.invalidURL
    }
    
    // Fetch data
    guard let data = fetchedData else {
        throw NetworkError.noData
    }
    
    return data
}

// Usage
do {
    let data = try fetchData(from: "https://api.example.com")
    print("Success: \(data)")
} catch NetworkError.invalidURL {
    print("Invalid URL")
} catch NetworkError.noData {
    print("No data received")
} catch {
    print("Other error: \(error)")
}
```

### Result Type

```swift
func fetchUser(id: String) -> Result<User, Error> {
    do {
        let user = try performFetch(id: id)
        return .success(user)
    } catch {
        return .failure(error)
    }
}

// Usage
let result = fetchUser(id: "123")
switch result {
case .success(let user):
    print(user.name)
case .failure(let error):
    print("Error: \(error)")
}

// Map and flatMap
let userName = fetchUser(id: "123")
    .map { $0.name }
    .mapError { $0 as NSError }
```

### Try Variants

```swift
// try - propagates error
let data = try fetchData()

// try? - converts to optional
if let data = try? fetchData() {
    print("Success")
}

// try! - force unwrap (crashes on error)
let data = try! fetchData() // Use sparingly
```

## Optionals

### Optional Binding

```swift
// if let
if let name = user?.name {
    print(name)
}

// guard let
guard let name = user?.name else {
    return
}
print(name)

// Multiple bindings
if let name = user?.name,
   let age = user?.age,
   age >= 18 {
    print("\(name) is an adult")
}
```

### Optional Chaining

```swift
let streetName = user?.address?.street?.name

// With function calls
let count = user?.posts?.filter { $0.isPublished }?.count
```

### Nil Coalescing

```swift
let displayName = user?.name ?? "Guest"

// Chaining
let name = user?.nickname ?? user?.name ?? "Unknown"
```

### Optional Map and FlatMap

```swift
let uppercasedName = user?.name.map { $0.uppercased() }

let user: User? = getUser()
let address: Address? = user.flatMap { $0.address }
```

## Collections

### Arrays

```swift
var numbers = [1, 2, 3, 4, 5]

// Functional operations
let doubled = numbers.map { $0 * 2 }
let evens = numbers.filter { $0 % 2 == 0 }
let sum = numbers.reduce(0, +)

// First and last
let first = numbers.first // Optional
let last = numbers.last // Optional

// Safe subscripting
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

let element = numbers[safe: 10] // nil instead of crash
```

### Sets

```swift
var uniqueNumbers: Set<Int> = [1, 2, 3, 3, 4]
// uniqueNumbers = [1, 2, 3, 4]

// Set operations
let a: Set = [1, 2, 3, 4]
let b: Set = [3, 4, 5, 6]

let union = a.union(b) // [1, 2, 3, 4, 5, 6]
let intersection = a.intersection(b) // [3, 4]
let difference = a.subtracting(b) // [1, 2]
```

### Dictionaries

```swift
var scores: [String: Int] = ["Alice": 95, "Bob": 87]

// Safe access
let aliceScore = scores["Alice"] // Optional

// Default values
let charlieScore = scores["Charlie", default: 0]

// Updating
scores["Alice"] = 98
scores.updateValue(90, forKey: "Bob")

// Mapping
let doubled = scores.mapValues { $0 * 2 }
```

### Sequence Operations

```swift
let numbers = [1, 2, 3, 4, 5]

// compactMap - removes nils
let strings = ["1", "2", "three", "4"]
let validNumbers = strings.compactMap { Int($0) } // [1, 2, 4]

// flatMap - flattens nested arrays
let nested = [[1, 2], [3, 4], [5]]
let flattened = nested.flatMap { $0 } // [1, 2, 3, 4, 5]

// contains
let hasEven = numbers.contains { $0 % 2 == 0 }

// allSatisfy
let allPositive = numbers.allSatisfy { $0 > 0 }

// first(where:)
let firstEven = numbers.first { $0 % 2 == 0 }
```

## Protocols and Generics

### Protocol-Oriented Programming

```swift
protocol Drawable {
    func draw() -> String
}

protocol Colorable {
    var color: String { get set }
}

struct Circle: Drawable, Colorable {
    var color: String
    var radius: Double
    
    func draw() -> String {
        "Circle with radius \(radius) in \(color)"
    }
}

// Protocol extensions
extension Drawable {
    func describe() -> String {
        "Drawing: \(draw())"
    }
}
```

### Associated Types

```swift
protocol Container {
    associatedtype Item
    var items: [Item] { get set }
    mutating func add(_ item: Item)
}

struct IntContainer: Container {
    var items: [Int] = []
    
    mutating func add(_ item: Int) {
        items.append(item)
    }
}
```

### Generics

```swift
// Generic function
func swap<T>(_ a: inout T, _ b: inout T) {
    let temp = a
    a = b
    b = temp
}

// Generic type
struct Stack<Element> {
    private var items: [Element] = []
    
    mutating func push(_ item: Element) {
        items.append(item)
    }
    
    mutating func pop() -> Element? {
        items.popLast()
    }
}

// Type constraints
func findIndex<T: Equatable>(of valueToFind: T, in array: [T]) -> Int? {
    for (index, value) in array.enumerated() {
        if value == valueToFind {
            return index
        }
    }
    return nil
}
```

### Protocol Composition

```swift
protocol Named {
    var name: String { get }
}

protocol Aged {
    var age: Int { get }
}

func greet(_ person: Named & Aged) {
    print("Hello \(person.name), you are \(person.age) years old")
}
```

## Memory Management

### ARC Basics

```swift
class Person {
    let name: String
    var apartment: Apartment?
    
    init(name: String) {
        self.name = name
    }
    
    deinit {
        print("\(name) is being deinitialized")
    }
}

var person: Person? = Person(name: "John")
person = nil // Deinitializer called
```

### Strong Reference Cycles

```swift
// ❌ Bad: Strong reference cycle
class Person {
    var apartment: Apartment?
}

class Apartment {
    var tenant: Person?
}

// ✅ Good: Break cycle with weak
class Apartment {
    weak var tenant: Person?
}
```

### Weak and Unowned

```swift
// weak - optional, becomes nil when deallocated
class Person {
    weak var friend: Person?
}

// unowned - non-optional, must always have a value
class Customer {
    var card: CreditCard?
}

class CreditCard {
    unowned let customer: Customer
    
    init(customer: Customer) {
        self.customer = customer
    }
}
```

### Closure Capture Lists

```swift
// ❌ Bad: Strong reference cycle
class ViewModel {
    var onUpdate: (() -> Void)?
    
    func setup() {
        onUpdate = {
            self.refresh()
        }
    }
}

// ✅ Good: Weak self
class ViewModel {
    var onUpdate: (() -> Void)?
    
    func setup() {
        onUpdate = { [weak self] in
            self?.refresh()
        }
    }
}

// ✅ Good: Unowned when self will always exist
class ViewController {
    lazy var button: UIButton = {
        let button = UIButton()
        button.addAction(UIAction { [unowned self] _ in
            self.handleTap()
        }, for: .touchUpInside)
        return button
    }()
}
```

## Swift 6 Features

### Typed Throws

```swift
enum ValidationError: Error {
    case tooShort
    case tooLong
    case invalidCharacters
}

func validate(password: String) throws(ValidationError) {
    if password.count < 8 {
        throw .tooShort
    }
    if password.count > 128 {
        throw .tooLong
    }
}

// Caller knows exact error type
do {
    try validate(password: "abc")
} catch .tooShort {
    print("Password too short")
} catch .tooLong {
    print("Password too long")
}
```

### Noncopyable Types

```swift
struct FileHandle: ~Copyable {
    private let descriptor: Int32
    
    init(path: String) throws {
        descriptor = open(path, O_RDONLY)
    }
    
    deinit {
        close(descriptor)
    }
    
    consuming func close() {
        // Explicitly consume the value
    }
}
```

### Complete Concurrency Checking

```swift
// Strict concurrency checking
@preconcurrency protocol LegacyProtocol {
    func oldMethod()
}

// Sendable conformance
struct User: Sendable {
    let id: UUID
    let name: String
}

// Global actor isolation
@MainActor
class UIManager {
    var currentTheme: Theme
}
```

## Best Practices Summary

1. **Use value types**: Prefer structs over classes when possible
2. **Protocol-oriented**: Design with protocols and extensions
3. **Async/await**: Use for all asynchronous operations
4. **Avoid force unwrapping**: Use optional binding instead
5. **Guard for early returns**: Keep happy path unindented
6. **Weak references**: Break retain cycles in closures
7. **Actors for shared state**: Protect mutable state with actors
8. **Type inference**: Let Swift infer types when obvious
9. **Error handling**: Use proper error handling, not optionals
10. **Generics**: Write reusable, type-safe code
