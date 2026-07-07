import SwiftUI

struct SettingsTab: View {
    @EnvironmentObject private var store: GameSessionStore
    @EnvironmentObject private var locationService: LocationService
    @StateObject private var notificationService = NotificationService.shared
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                notificationSection
                locationSection
                resetSection
            }
            .padding(20)
        }
        .background(PlayHubScreenBackground())
        .navigationTitle("Settings")
        .confirmationDialog("Reset all PlayHub stats?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset All Stats", role: .destructive) {
                store.resetAll()
            }
            Button("Cancel", role: .cancel) { }
        }
        .task {
            await notificationService.refreshAuthorization()
        }
    }

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Daily Challenge", systemImage: "bell.badge.fill")
                .font(.title3.bold())
                .foregroundStyle(PlayHubTheme.ink)

            Toggle(
                "Notifications",
                isOn: Binding(
                    get: { notificationService.notificationsEnabled },
                    set: { notificationService.setNotificationsEnabled($0) }
                )
            )
            .tint(PlayHubTheme.orange)

            DatePicker(
                "Challenge Time",
                selection: Binding(
                    get: { notificationService.dailyChallengeTime },
                    set: { notificationService.setDailyChallengeTime($0) }
                ),
                displayedComponents: .hourAndMinute
            )
            .disabled(!notificationService.notificationsEnabled)

            Text(notificationService.permissionLabel)
                .font(.caption)
                .foregroundStyle(PlayHubTheme.mutedInk)
        }
        .padding(16)
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Location", systemImage: "location.fill")
                .font(.title3.bold())
                .foregroundStyle(PlayHubTheme.ink)

            Text(locationService.permissionLabel)
                .font(.subheadline)
                .foregroundStyle(PlayHubTheme.mutedInk)

            if let lastErrorMessage = locationService.lastErrorMessage {
                Text(lastErrorMessage)
                    .font(.caption)
                    .foregroundStyle(PlayHubTheme.berry)
            }

            Button {
                locationService.requestPermission()
            } label: {
                Label("Refresh Location", systemImage: "location.circle.fill")
            }
            .buttonStyle(PlayHubSecondaryButtonStyle())
        }
        .padding(16)
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Stats", systemImage: "trash.fill")
                .font(.title3.bold())
                .foregroundStyle(PlayHubTheme.ink)

            Text("\(store.sessions.count) saved sessions")
                .font(.subheadline)
                .foregroundStyle(PlayHubTheme.mutedInk)

            Button(role: .destructive) {
                confirmReset = true
            } label: {
                Label("Reset All Stats", systemImage: "trash")
            }
            .buttonStyle(PlayHubSecondaryButtonStyle())
        }
        .padding(16)
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    NavigationStack { SettingsTab() }
        .environmentObject(GameSessionStore.shared)
        .environmentObject(LocationService.shared)
}
