import SwiftUI

@main
struct PlayHubApp: App {
    @StateObject private var sessionStore = GameSessionStore.shared
    @StateObject private var locationService = LocationService.shared

    var body: some Scene {
        WindowGroup {
            PlayHubShellView()
                .environmentObject(sessionStore)
                .environmentObject(locationService)
                .task {
                    locationService.requestPermission()
                }
        }
    }
}

struct PlayHubShellView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeTab()
            }
            .tabItem {
                Label("Home", systemImage: "gamecontroller.fill")
            }

            NavigationStack {
                StatsTab()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }

            NavigationStack {
                MapTab()
            }
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }

            NavigationStack {
                SettingsTab()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(PlayHubTheme.orange)
    }
}

#Preview {
    PlayHubShellView()
        .environmentObject(GameSessionStore.shared)
        .environmentObject(LocationService.shared)
}
