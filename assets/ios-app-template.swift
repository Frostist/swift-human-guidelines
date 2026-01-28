// iOS App Template
// Modern SwiftUI app structure following Apple's best practices

import SwiftUI

@main
struct MyApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

// MARK: - App State
@MainActor
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    func signIn(email: String, password: String) async throws {
        // Authentication logic
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
    }
}

// MARK: - Root View
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

// MARK: - Main Navigation
struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            
            NavigationStack {
                ExploreView()
            }
            .tabItem {
                Label("Explore", systemImage: "magnifyingglass")
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

// MARK: - Home View
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                NavigationLink(value: item) {
                    ItemRow(item: item)
                }
            }
        }
        .navigationTitle("Home")
        .navigationDestination(for: Item.self) { item in
            ItemDetailView(item: item)
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadItems()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}

// MARK: - View Model
@MainActor
class HomeViewModel: ObservableObject {
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
    
    func refresh() async {
        await loadItems()
    }
}

// MARK: - Models
struct Item: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let imageURL: URL?
}

struct User: Identifiable, Codable {
    let id: UUID
    let name: String
    let email: String
    let avatarURL: URL?
}

// MARK: - Repository
protocol ItemRepository {
    func fetchItems() async throws -> [Item]
    func fetchItem(id: UUID) async throws -> Item
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
}

// MARK: - Reusable Components
struct ItemRow: View {
    let item: Item
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: item.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                Text(item.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ItemDetailView: View {
    let item: Item
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: item.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.title)
                        .bold()
                    
                    Text(item.description)
                        .font(.body)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExploreView: View {
    var body: some View {
        Text("Explore")
            .navigationTitle("Explore")
    }
}

struct ProfileView: View {
    var body: some View {
        Text("Profile")
            .navigationTitle("Profile")
    }
}

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }
                
                Section {
                    Button("Sign In") {
                        Task {
                            await signIn()
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                }
            }
            .navigationTitle("Sign In")
        }
    }
    
    private func signIn() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await appState.signIn(email: email, password: password)
        } catch {
            print("Sign in failed: \(error)")
        }
    }
}
