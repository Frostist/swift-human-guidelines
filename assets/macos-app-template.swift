// macOS App Template
// Modern SwiftUI app structure for macOS following Apple's best practices

import SwiftUI

@main
struct MyMacApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 600)
        }
        .commands {
            SidebarCommands()
            ToolbarCommands()
            
            CommandGroup(after: .newItem) {
                Button("New Window") {
                    // Open new window
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}

// MARK: - App State
@MainActor
class AppState: ObservableObject {
    @Published var selectedItem: Item?
    @Published var items: [Item] = []
    @Published var isLoading = false
}

// MARK: - Root View
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DetailView()
        }
    }
}

// MARK: - Sidebar
struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    
    var body: some View {
        List(selection: $appState.selectedItem) {
            Section("Library") {
                Label("All Items", systemImage: "tray.fill")
                Label("Favorites", systemImage: "star.fill")
                Label("Recent", systemImage: "clock.fill")
            }
            
            Section("Collections") {
                ForEach(appState.items) { item in
                    Label(item.title, systemImage: "folder")
                        .tag(item)
                }
            }
        }
        .navigationTitle("Sidebar")
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: addItem) {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .task {
            await loadItems()
        }
    }
    
    private func addItem() {
        // Add new item
    }
    
    private func loadItems() async {
        // Load items
    }
}

// MARK: - Detail View
struct DetailView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if let item = appState.selectedItem {
                ItemDetailView(item: item)
            } else {
                EmptyStateView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ItemDetailView: View {
    let item: Item
    @State private var isEditing = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.title)
                            .font(.largeTitle)
                            .bold()
                        
                        Text(item.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Edit") {
                        isEditing = true
                    }
                }
                
                Divider()
                
                // Content sections
                VStack(alignment: .leading, spacing: 16) {
                    Text("Details")
                        .font(.headline)
                    
                    // Detail content
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: shareItem) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button(action: deleteItem) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditItemView(item: item)
        }
    }
    
    private func shareItem() {
        // Share functionality
    }
    
    private func deleteItem() {
        // Delete functionality
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No Selection")
                .font(.title2)
            
            Text("Select an item from the sidebar")
                .foregroundStyle(.secondary)
        }
    }
}

struct EditItemView: View {
    let item: Item
    @Environment(\.dismiss) var dismiss
    @State private var title: String
    @State private var description: String
    
    init(item: Item) {
        self.item = item
        _title = State(initialValue: item.title)
        _description = State(initialValue: item.description)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Edit Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
    
    private func saveChanges() {
        // Save changes
    }
}

// MARK: - Settings
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
            
            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("showWelcomeScreen") private var showWelcomeScreen = true
    @AppStorage("autoSave") private var autoSave = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Show welcome screen", isOn: $showWelcomeScreen)
                Toggle("Auto-save changes", isOn: $autoSave)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("colorScheme") private var colorScheme = "system"
    
    var body: some View {
        Form {
            Section {
                Picker("Appearance", selection: $colorScheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AdvancedSettingsView: View {
    var body: some View {
        Form {
            Section {
                Text("Advanced settings")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Models
struct Item: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let imageURL: URL?
}

// MARK: - View Model
@MainActor
class ItemListViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let repository: ItemRepository
    
    init(repository: ItemRepository = NetworkItemRepository()) {
        self.repository = repository
    }
    
    func loadItems() async {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            items = try await repository.fetchItems()
        } catch {
            self.error = error
        }
    }
}

// MARK: - Repository
protocol ItemRepository {
    func fetchItems() async throws -> [Item]
    func fetchItem(id: UUID) async throws -> Item
    func saveItem(_ item: Item) async throws
    func deleteItem(id: UUID) async throws
}

class NetworkItemRepository: ItemRepository {
    private let baseURL = URL(string: "https://api.example.com")!
    
    func fetchItems() async throws -> [Item] {
        let url = baseURL.appendingPathComponent("items")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Item].self, from: data)
    }
    
    func fetchItem(id: UUID) async throws -> Item {
        let url = baseURL.appendingPathComponent("items/\(id)")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(Item.self, from: data)
    }
    
    func saveItem(_ item: Item) async throws {
        let url = baseURL.appendingPathComponent("items/\(item.id)")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try JSONEncoder().encode(item)
        let _ = try await URLSession.shared.data(for: request)
    }
    
    func deleteItem(id: UUID) async throws {
        let url = baseURL.appendingPathComponent("items/\(id)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let _ = try await URLSession.shared.data(for: request)
    }
}
