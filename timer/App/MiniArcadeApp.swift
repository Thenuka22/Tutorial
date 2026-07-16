import SwiftUI

@main
struct MiniArcadeApp: App {
    @StateObject private var sessionStore = GameSessionStore.shared
    @StateObject private var settingsStore = GameSettingsStore.shared
    @StateObject private var locationService = LocationService.shared

    var body: some Scene {
        WindowGroup {
            LaunchSequenceView {
                MiniArcadeShellView()
                    .task {
                        locationService.requestPermission()
                        AudioService.shared.sync(with: settingsStore)
                    }
            }
                .environmentObject(sessionStore)
                .environmentObject(settingsStore)
                .environmentObject(locationService)
        }
    }
}

struct MiniArcadeShellView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeTab()
            }
            .arcadeTabBarStyle()
            .tabItem {
                Label("Home", systemImage: "gamecontroller.fill")
            }

            NavigationStack {
                StatsTab()
            }
            .arcadeTabBarStyle()
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }

            NavigationStack {
                MapTab()
            }
            .arcadeTabBarStyle()
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }

            NavigationStack {
                SettingsTab()
            }
            .arcadeTabBarStyle()
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(MiniArcadeTheme.gold)
        .preferredColorScheme(.dark)
    }
}

private extension View {
    func arcadeTabBarStyle() -> some View {
        toolbarBackground(MiniArcadeTheme.wood, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarColorScheme(.dark, for: .tabBar)
    }
}

#Preview {
    MiniArcadeShellView()
        .environmentObject(GameSessionStore.shared)
        .environmentObject(GameSettingsStore.shared)
        .environmentObject(LocationService.shared)
}
