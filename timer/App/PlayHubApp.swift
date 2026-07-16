import SwiftUI

@main
struct GameArcadeApp: App {
    @StateObject private var sessionStore = GameSessionStore.shared
    @StateObject private var settingsStore = GameSettingsStore.shared
    @StateObject private var locationService = LocationService.shared

    var body: some Scene {
        WindowGroup {
            GameArcadeShellView()
                .environmentObject(sessionStore)
                .environmentObject(settingsStore)
                .environmentObject(locationService)
                .task {
                    locationService.requestPermission()
                    AudioService.shared.sync(with: settingsStore)
                }
        }
    }
}

struct GameArcadeShellView: View {
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
    GameArcadeShellView()
        .environmentObject(GameSessionStore.shared)
        .environmentObject(GameSettingsStore.shared)
        .environmentObject(LocationService.shared)
}
