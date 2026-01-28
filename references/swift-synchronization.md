# Swift Synchronization Library (Swift 6.0+)

**Available:** Swift 6.0+
**Documentation:** [Swift 6 Announcement](https://www.swift.org/blog/announcing-swift-6/)
**Package:** `import Synchronization`

## Overview

The Synchronization library introduced in Swift 6 provides low-level concurrency primitives for safe concurrent programming. It includes atomic operations and a mutex API that work seamlessly with Swift's data-race safety guarantees.

## Key Features

- **Atomic operations**: Lock-free atomic read, write, and modify operations
- **Mutex API**: Safe mutual exclusion for protecting shared mutable state
- **Data-race safety**: Full integration with Swift 6 concurrency model
- **Performance**: Optimized low-level primitives
- **Cross-platform**: Works on all Swift platforms

## Atomic Operations

### Atomic Types

```swift
import Synchronization

// Available atomic types
let atomicInt = Atomic<Int>(0)
let atomicBool = Atomic<Bool>(false)
let atomicPointer = Atomic<UnsafeMutablePointer<Data>?>(nil)

// Atomic operations are lock-free and thread-safe
```

### Basic Operations

```swift
class Counter {
    private let count = Atomic<Int>(0)

    func increment() {
        count.wrappingAdd(1, ordering: .relaxed)
    }

    func decrement() {
        count.wrappingSubtract(1, ordering: .relaxed)
    }

    func getValue() -> Int {
        count.load(ordering: .relaxed)
    }

    func reset() {
        count.store(0, ordering: .relaxed)
    }
}

// Thread-safe usage
let counter = Counter()

Task {
    for _ in 0..<1000 {
        counter.increment()
    }
}

Task {
    for _ in 0..<1000 {
        counter.increment()
    }
}

// Always equals 2000, no race conditions
await Task { counter.getValue() }.value
```

### Atomic Load and Store

```swift
class Configuration {
    private let isEnabled = Atomic<Bool>(false)

    func enable() {
        isEnabled.store(true, ordering: .releasing)
    }

    func disable() {
        isEnabled.store(false, ordering: .releasing)
    }

    func check() -> Bool {
        isEnabled.load(ordering: .acquiring)
    }
}
```

### Compare and Exchange

```swift
class ResourcePool {
    private let availableCount = Atomic<Int>(10)

    func tryAcquire() -> Bool {
        while true {
            let current = availableCount.load(ordering: .relaxed)

            if current == 0 {
                return false  // No resources available
            }

            let (exchanged, _) = availableCount.compareExchange(
                expected: current,
                desired: current - 1,
                ordering: .relaxed
            )

            if exchanged {
                return true  // Successfully acquired
            }

            // Retry if another thread modified the value
        }
    }

    func release() {
        availableCount.wrappingAdd(1, ordering: .relaxed)
    }
}
```

### Memory Ordering

Swift's atomic operations support different memory ordering semantics:

```swift
// .relaxed - No synchronization guarantees
atomicValue.store(42, ordering: .relaxed)

// .acquiring - Synchronize with releasing stores
let value = atomicValue.load(ordering: .acquiring)

// .releasing - Make previous writes visible to acquiring loads
atomicValue.store(42, ordering: .releasing)

// .acquiringAndReleasing - Both acquire and release semantics
atomicValue.store(42, ordering: .acquiringAndReleasing)

// .sequentiallyConsistent - Strongest guarantees, total order
atomicValue.store(42, ordering: .sequentiallyConsistent)
```

## Mutex

### Basic Mutex Usage

```swift
import Synchronization

class BankAccount {
    private let balanceMutex = Mutex<Double>(0.0)

    func deposit(_ amount: Double) {
        balanceMutex.withLock { balance in
            balance += amount
        }
    }

    func withdraw(_ amount: Double) -> Bool {
        balanceMutex.withLock { balance in
            guard balance >= amount else {
                return false
            }
            balance -= amount
            return true
        }
    }

    func getBalance() -> Double {
        balanceMutex.withLock { $0 }
    }
}

// Thread-safe usage
let account = BankAccount()

Task {
    account.deposit(100)
}

Task {
    account.withdraw(50)
}
```

### Mutex vs Actor

```swift
// ✅ Use Mutex for: Simple synchronization primitives
class Cache<Key: Hashable, Value> {
    private let storage = Mutex<[Key: Value]>([:])

    func get(_ key: Key) -> Value? {
        storage.withLock { $0[key] }
    }

    func set(_ key: Key, value: Value) {
        storage.withLock { $0[key] = value }
    }
}

// ✅ Use Actor for: Higher-level concurrent types
actor UserSession {
    private var user: User?
    private var authToken: String?

    func login(user: User, token: String) {
        self.user = user
        self.authToken = token
    }

    func logout() {
        user = nil
        authToken = nil
    }
}
```

### Nested Locking

```swift
class NestedLockExample {
    private let outerMutex = Mutex<Int>(0)
    private let innerMutex = Mutex<String>("")

    func safeOperation() {
        outerMutex.withLock { outer in
            outer += 1

            // ✅ Safe: Different mutexes
            innerMutex.withLock { inner in
                inner = "Updated"
            }
        }
    }

    func unsafeOperation() {
        outerMutex.withLock { outer in
            // ❌ DEADLOCK: Same mutex
            // outerMutex.withLock { ... }
        }
    }
}
```

## Real-World Examples

### Thread-Safe Cache

```swift
import Synchronization

class ThreadSafeCache<Key: Hashable, Value> {
    private struct CacheEntry {
        let value: Value
        let timestamp: Date
        let ttl: TimeInterval
    }

    private let storage = Mutex<[Key: CacheEntry]>([:])
    private let accessCount = Atomic<Int>(0)

    func get(_ key: Key) -> Value? {
        accessCount.wrappingAdd(1, ordering: .relaxed)

        return storage.withLock { cache in
            guard let entry = cache[key] else {
                return nil
            }

            // Check if expired
            if Date().timeIntervalSince(entry.timestamp) > entry.ttl {
                cache.removeValue(forKey: key)
                return nil
            }

            return entry.value
        }
    }

    func set(_ key: Key, value: Value, ttl: TimeInterval = 300) {
        storage.withLock { cache in
            cache[key] = CacheEntry(
                value: value,
                timestamp: Date(),
                ttl: ttl
            )
        }
    }

    func clear() {
        storage.withLock { cache in
            cache.removeAll()
        }
    }

    func stats() -> (entries: Int, accesses: Int) {
        let entries = storage.withLock { $0.count }
        let accesses = accessCount.load(ordering: .relaxed)
        return (entries, accesses)
    }
}
```

### Reference Counting

```swift
class ReferenceCounter {
    private let count = Atomic<Int>(1)

    func retain() {
        count.wrappingAdd(1, ordering: .relaxed)
    }

    func release() -> Bool {
        let old = count.wrappingSubtract(1, ordering: .releasing)
        if old == 1 {
            // Last reference released
            return true
        }
        return false
    }

    func strongCount() -> Int {
        count.load(ordering: .acquiring)
    }
}

class Resource {
    private let refCount = ReferenceCounter()

    func addReference() {
        refCount.retain()
    }

    func removeReference() {
        if refCount.release() {
            cleanup()
        }
    }

    private func cleanup() {
        // Deallocate resources
    }
}
```

### Lock-Free Queue

```swift
class LockFreeQueue<Element> {
    private struct Node {
        let value: Element
        var next: Atomic<UnsafeMutablePointer<Node>?>
    }

    private let head = Atomic<UnsafeMutablePointer<Node>?>(nil)
    private let tail = Atomic<UnsafeMutablePointer<Node>?>(nil)

    func enqueue(_ value: Element) {
        let newNode = UnsafeMutablePointer<Node>.allocate(capacity: 1)
        newNode.initialize(to: Node(value: value, next: Atomic(nil)))

        while true {
            let currentTail = tail.load(ordering: .acquiring)

            if currentTail == nil {
                // Empty queue
                if head.compareExchange(
                    expected: nil,
                    desired: newNode,
                    ordering: .releasing
                ).exchanged {
                    tail.store(newNode, ordering: .releasing)
                    return
                }
            } else {
                let next = currentTail!.pointee.next

                if next.compareExchange(
                    expected: nil,
                    desired: newNode,
                    ordering: .releasing
                ).exchanged {
                    tail.store(newNode, ordering: .releasing)
                    return
                }
            }
        }
    }

    func dequeue() -> Element? {
        while true {
            let currentHead = head.load(ordering: .acquiring)

            guard let headNode = currentHead else {
                return nil  // Queue is empty
            }

            let next = headNode.pointee.next.load(ordering: .acquiring)

            if head.compareExchange(
                expected: currentHead,
                desired: next,
                ordering: .releasing
            ).exchanged {
                let value = headNode.pointee.value
                headNode.deallocate()
                return value
            }
        }
    }
}
```

### Atomic Flags

```swift
class Coordinator {
    private let isInitialized = Atomic<Bool>(false)
    private let isShutdown = Atomic<Bool>(false)

    func initialize() {
        let (exchanged, _) = isInitialized.compareExchange(
            expected: false,
            desired: true,
            ordering: .acquiringAndReleasing
        )

        if exchanged {
            performInitialization()
        }
    }

    func shutdown() {
        let (exchanged, _) = isShutdown.compareExchange(
            expected: false,
            desired: true,
            ordering: .acquiringAndReleasing
        )

        if exchanged {
            performShutdown()
        }
    }

    func isReady() -> Bool {
        isInitialized.load(ordering: .acquiring) &&
        !isShutdown.load(ordering: .acquiring)
    }

    private func performInitialization() {
        // Setup code
    }

    private func performShutdown() {
        // Cleanup code
    }
}
```

## Performance Considerations

### When to Use Atomics

```swift
// ✅ Good: Simple counters and flags
let requestCount = Atomic<Int>(0)
let isEnabled = Atomic<Bool>(true)

// ✅ Good: Lock-free data structures
class LockFreeStack<T> { /* ... */ }

// ❌ Bad: Complex state (use Mutex or Actor instead)
// let complexState = Atomic<ComplexStruct>(...)
```

### When to Use Mutex

```swift
// ✅ Good: Protecting collections
let mutex = Mutex<[String: Value]>([:])

// ✅ Good: Multiple related values
let mutex = Mutex<(count: Int, total: Double)>((0, 0.0))

// ❌ Bad: Single primitive value (use Atomic)
// let mutex = Mutex<Int>(0)  // Use Atomic<Int> instead
```

### Benchmarking

```swift
import Synchronization

func benchmarkAtomic() {
    let iterations = 1_000_000
    let atomic = Atomic<Int>(0)

    let start = Date()

    Task {
        for _ in 0..<iterations {
            atomic.wrappingAdd(1, ordering: .relaxed)
        }
    }

    Task {
        for _ in 0..<iterations {
            atomic.wrappingAdd(1, ordering: .relaxed)
        }
    }

    // Measure time...
}
```

## Integration with Swift Concurrency

### With Actors

```swift
actor DataManager {
    private let cache = Mutex<[String: Data]>([:])
    private let cacheHits = Atomic<Int>(0)

    func getData(_ key: String) -> Data? {
        let data = cache.withLock { $0[key] }

        if data != nil {
            cacheHits.wrappingAdd(1, ordering: .relaxed)
        }

        return data
    }

    func stats() -> (hits: Int, entries: Int) {
        let hits = cacheHits.load(ordering: .relaxed)
        let entries = cache.withLock { $0.count }
        return (hits, entries)
    }
}
```

### With @Sendable Closures

```swift
func processWithProgress<T>(
    items: [T],
    progress: @Sendable (Int) -> Void,
    process: @Sendable (T) -> Void
) {
    let completed = Atomic<Int>(0)

    for item in items {
        Task {
            process(item)

            let newCount = completed.wrappingAdd(1, ordering: .relaxed) + 1
            progress(newCount)
        }
    }
}
```

## Best Practices

1. **Prefer actors**: For high-level concurrent types
2. **Use atomics for**: Simple counters, flags, and lock-free structures
3. **Use mutex for**: Protecting collections and multiple related values
4. **Avoid deadlocks**: Never lock the same mutex twice
5. **Choose correct ordering**: Use `.relaxed` unless you need synchronization
6. **Profile performance**: Measure before optimizing
7. **Document locking order**: When using multiple mutexes
8. **Test thoroughly**: Concurrency bugs are hard to reproduce

## Common Pitfalls

```swift
// ❌ Bad: Deadlock
let mutex = Mutex<Int>(0)
mutex.withLock { value in
    mutex.withLock { inner in  // DEADLOCK!
        inner += 1
    }
}

// ❌ Bad: Data race with incorrect ordering
let flag = Atomic<Bool>(false)
var data: Int = 0

// Thread 1
data = 42
flag.store(true, ordering: .relaxed)  // Should be .releasing

// Thread 2
if flag.load(ordering: .relaxed) {  // Should be .acquiring
    print(data)  // Might not see 42!
}

// ✅ Good: Correct ordering
// Thread 1
data = 42
flag.store(true, ordering: .releasing)

// Thread 2
if flag.load(ordering: .acquiring) {
    print(data)  // Always sees 42
}
```

## Resources

- [Swift 6 Announcement](https://www.swift.org/blog/announcing-swift-6/)
- [Synchronization Module Documentation](https://developer.apple.com/documentation/synchronization)
- [Swift Concurrency Guide](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Swift Evolution Proposals](https://github.com/swiftlang/swift-evolution)
