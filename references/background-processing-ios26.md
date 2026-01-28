# Background Processing in iOS 26

**Available:** iOS 26.0+, iPadOS 26.0+
**Documentation:** [Finish tasks in the background - WWDC25](https://developer.apple.com/videos/play/wwdc2025/227/)
**Framework:** BackgroundTasks

## Overview

iOS 26 introduces `BGContinuedProcessingTask`, a new background task type that allows apps to complete work started in the foreground even after the user backgrounds the app. Unlike traditional background tasks, continued processing tasks maintain a higher priority and can access GPU resources on supported devices.

## BGContinuedProcessingTask

### Key Features

- **Continuation from foreground**: Complete work the user initiated
- **Extended execution time**: Up to 30 seconds (vs 30 seconds for BGProcessingTask)
- **GPU access**: On iPad Pro M1+ and iPhone 15 Pro+
- **Higher priority**: More CPU time than regular background tasks
- **User-visible**: System may show indicator that app is finishing work

### When to Use

**✅ Good use cases:**
- Finishing photo/video export user just started
- Completing file downloads or uploads
- Finishing document processing
- Saving complex user edits
- Completing game level saves

**❌ Not appropriate for:**
- Long-running operations (> 30 seconds)
- Work not initiated by user
- Periodic maintenance tasks (use BGProcessingTask)
- Preemptive downloads (use BGAppRefreshTask)

## Basic Implementation

### 1. Register Task Identifier

**Info.plist:**
```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.yourapp.continued-processing</string>
</array>
```

### 2. Register Handler

```swift
import BackgroundTasks

@main
struct MyApp: App {
    init() {
        registerBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.yourapp.continued-processing",
            using: nil
        ) { task in
            handleContinuedProcessing(task: task as! BGContinuedProcessingTask)
        }
    }
}
```

### 3. Schedule When Backgrounding

```swift
class ExportManager: ObservableObject {
    @Published var isExporting = false

    func startExport(_ video: Video) async {
        isExporting = true

        // Start export
        await performExport(video)

        // If user backgrounds app, schedule continuation
        Task {
            await scheduleContinuation()
        }
    }

    private func scheduleContinuation() async {
        let request = BGContinuedProcessingTaskRequest(
            identifier: "com.yourapp.continued-processing"
        )

        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Continued processing scheduled")
        } catch {
            print("Failed to schedule: \(error)")
        }
    }
}
```

## Complete Example: Video Export

```swift
import SwiftUI
import BackgroundTasks
import AVFoundation

@MainActor
class VideoExporter: ObservableObject {
    @Published var progress: Double = 0
    @Published var isExporting = false
    @Published var exportComplete = false

    private var exportSession: AVAssetExportSession?
    private var backgroundTask: BGContinuedProcessingTask?

    func exportVideo(_ asset: AVAsset, to url: URL) async throws {
        isExporting = true
        defer { isExporting = false }

        // Create export session
        guard let session = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPreset1920x1080
        ) else {
            throw ExportError.sessionCreationFailed
        }

        session.outputURL = url
        session.outputFileType = .mp4
        exportSession = session

        // Monitor progress
        let progressTask = Task {
            while !Task.isCancelled && session.progress < 1.0 {
                await MainActor.run {
                    progress = Double(session.progress)
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }

        // Start export
        await session.export()

        progressTask.cancel()

        if session.status == .completed {
            exportComplete = true
        } else if let error = session.error {
            throw error
        }
    }

    func scheduleBackgroundContinuation() {
        let request = BGContinuedProcessingTaskRequest(
            identifier: "com.yourapp.video-export"
        )

        try? BGTaskScheduler.shared.submit(request)
    }

    func handleBackgroundTask(_ task: BGContinuedProcessingTask) {
        backgroundTask = task

        // Continue export in background
        Task {
            guard let session = exportSession else {
                task.setTaskCompleted(success: false)
                return
            }

            // Monitor for expiration
            task.expirationHandler = {
                session.cancelExport()
                self.exportSession = nil
            }

            // Wait for export to complete
            await session.export()

            if session.status == .completed {
                await MainActor.run {
                    self.exportComplete = true
                }
                task.setTaskCompleted(success: true)
            } else {
                task.setTaskCompleted(success: false)
            }

            self.exportSession = nil
            self.backgroundTask = nil
        }
    }
}

struct VideoExportView: View {
    @StateObject private var exporter = VideoExporter()
    @Environment(\.scenePhase) private var scenePhase
    let video: Video

    var body: some View {
        VStack {
            if exporter.isExporting {
                VStack {
                    ProgressView(value: exporter.progress)
                    Text("\(Int(exporter.progress * 100))%")
                }
            } else if exporter.exportComplete {
                Label("Export Complete", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Export Video") {
                    Task {
                        try? await exporter.exportVideo(
                            video.asset,
                            to: exportURL
                        )
                    }
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background && exporter.isExporting {
                exporter.scheduleBackgroundContinuation()
            }
        }
    }
}
```

## Background GPU Access

On supported devices (iPad Pro M1+, iPhone 15 Pro+), continued processing tasks can access the GPU:

```swift
import Metal

class GPUProcessor {
    private let device: MTLDevice?

    init() {
        device = MTLCreateSystemDefaultDevice()
    }

    func processImageInBackground(_ image: CIImage) -> CIImage? {
        guard let device = device else { return nil }

        let context = CIContext(mtlDevice: device)

        // Apply GPU-accelerated filters
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(1.2, forKey: kCIInputSaturationKey)
        filter?.setValue(0.1, forKey: kCIInputBrightnessKey)

        return filter?.outputImage
    }
}

func handleBackgroundProcessing(_ task: BGContinuedProcessingTask) {
    let processor = GPUProcessor()

    Task {
        // GPU operations work in background
        if let processedImage = processor.processImageInBackground(inputImage) {
            // Save processed image
            await saveImage(processedImage)
            task.setTaskCompleted(success: true)
        } else {
            task.setTaskCompleted(success: false)
        }
    }
}
```

## Task Management

### Monitoring Task Status

```swift
class TaskManager: ObservableObject {
    @Published var isBackgroundTaskActive = false
    private var currentTask: BGContinuedProcessingTask?

    func handleTask(_ task: BGContinuedProcessingTask) {
        currentTask = task
        isBackgroundTaskActive = true

        task.expirationHandler = {
            self.cleanup()
            task.setTaskCompleted(success: false)
        }

        performWork(task)
    }

    private func performWork(_ task: BGContinuedProcessingTask) {
        Task {
            let success = await doWork()

            await MainActor.run {
                isBackgroundTaskActive = false
            }

            task.setTaskCompleted(success: success)
            currentTask = nil
        }
    }

    private func cleanup() {
        // Cancel ongoing work
        // Save state
        // Release resources
    }
}
```

### Handling Expiration

```swift
func handleBackgroundTask(_ task: BGContinuedProcessingTask) {
    var workCompleted = false

    task.expirationHandler = {
        // Task is about to be terminated
        // Save state and cleanup

        if !workCompleted {
            self.savePartialProgress()
        }

        task.setTaskCompleted(success: workCompleted)
    }

    // Perform work
    Task {
        workCompleted = await performTimeConsumingWork()

        if workCompleted {
            task.setTaskCompleted(success: true)
        }
    }
}
```

## Best Practices

### 1. Check Task Remaining Time

```swift
func performWork(_ task: BGContinuedProcessingTask) async -> Bool {
    let chunks = divideWorkIntoChunks(totalWork)

    for chunk in chunks {
        // Periodically check if we're running out of time
        if task.isExpired {
            // Save progress and exit gracefully
            await saveProgress()
            return false
        }

        await processChunk(chunk)
    }

    return true
}
```

### 2. Provide User Feedback

```swift
struct BackgroundWorkIndicator: View {
    @StateObject private var taskManager = TaskManager()

    var body: some View {
        VStack {
            if taskManager.isBackgroundTaskActive {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Finishing export...")
                        .font(.caption)
                }
                .padding(8)
                .background(.regularMaterial)
                .cornerRadius(8)
            }

            ContentView()
        }
    }
}
```

### 3. Clean Resource Handling

```swift
class ResourceManager {
    private var tempFiles: [URL] = []
    private var backgroundTask: BGContinuedProcessingTask?

    func handleBackgroundWork(_ task: BGContinuedProcessingTask) {
        backgroundTask = task

        task.expirationHandler = { [weak self] in
            self?.cleanup()
        }

        Task {
            await doWork()
            cleanup()
            task.setTaskCompleted(success: true)
        }
    }

    private func cleanup() {
        // Remove temporary files
        for url in tempFiles {
            try? FileManager.default.removeItem(at: url)
        }
        tempFiles.removeAll()

        // Release other resources
        backgroundTask = nil
    }
}
```

## Debugging

### Testing in Xcode

```swift
// Simulate background task in Xcode debugger:
// 1. Run app
// 2. In LLDB console:
// e -l swift -- await BGTaskScheduler.shared.submit(BGContinuedProcessingTaskRequest(identifier: "com.yourapp.continued-processing"))

// Or use scheme configuration:
// Edit Scheme > Run > Options > Background Tasks
```

### Logging

```swift
import OSLog

let logger = Logger(subsystem: "com.yourapp", category: "BackgroundTasks")

func handleBackgroundTask(_ task: BGContinuedProcessingTask) {
    logger.info("Background task started: \(task.identifier)")

    task.expirationHandler = {
        logger.warning("Background task expiring: \(task.identifier)")
    }

    Task {
        let success = await performWork()
        logger.info("Background task completed: \(success)")
        task.setTaskCompleted(success: success)
    }
}
```

## System Limits

### Per-App Limits
- Maximum 1 active continued processing task at a time
- Task duration: Up to 30 seconds
- No guarantee of execution if device is under heavy load

### Device Requirements
- **GPU access**: iPad Pro M1+, iPhone 15 Pro+, Mac with Apple Silicon
- **All other features**: iOS 26+ on any device

## Comparison with Other Background Task Types

| Feature | BGContinuedProcessingTask | BGProcessingTask | BGAppRefreshTask |
|---------|--------------------------|------------------|------------------|
| Duration | Up to 30 seconds | Several minutes | 30 seconds |
| GPU Access | Yes (supported devices) | No | No |
| Priority | High | Low | Medium |
| Use Case | Finishing user work | Heavy processing | Quick refresh |
| When Run | Immediately after background | Device idle, plugged in | Opportunistic |

## Resources

- [WWDC25: Finish tasks in the background](https://developer.apple.com/videos/play/wwdc2025/227/)
- [iOS 26 Release Notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-26-release-notes)
- [BackgroundTasks Framework](https://developer.apple.com/documentation/backgroundtasks)
- [Background Execution Guide](https://developer.apple.com/documentation/uikit/app_and_environment/scenes/preparing_your_ui_to_run_in_the_background)
