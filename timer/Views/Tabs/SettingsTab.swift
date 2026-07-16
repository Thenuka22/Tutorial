import SwiftUI

struct SettingsTab: View {
    @EnvironmentObject private var store: GameSessionStore
    @EnvironmentObject private var settings: GameSettingsStore
    @EnvironmentObject private var locationService: LocationService
    @StateObject private var notificationService = NotificationService.shared
    @State private var confirmReset = false
    @State private var categories: [TriviaCategory] = [.any]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                audioSection
                defaultGameOptionsSection
                notificationSection
                locationSection
                resetSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 108)
        }
        .background(PlayHubScreenBackground())
        .navigationTitle("Settings")
        .confirmationDialog("Reset all Game Arcade stats?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset All Stats", role: .destructive) {
                store.resetAll()
            }
            Button("Cancel", role: .cancel) { }
        }
        .task {
            await notificationService.refreshAuthorization()
            await loadCategories()
        }
    }

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Audio & Feel", systemImage: "speaker.wave.2.fill")
                .font(.title3.bold())
                .foregroundStyle(PlayHubTheme.ink)

            HStack(spacing: 14) {
                artToggleButton(
                    isOn: $settings.musicEnabled,
                    onImage: GameArt.musicOn,
                    offImage: GameArt.musicOff,
                    label: "Music"
                )

                artToggleButton(
                    isOn: $settings.soundEffectsEnabled,
                    onImage: GameArt.soundOn,
                    offImage: GameArt.soundOff,
                    label: "Sound"
                )

                artToggleButton(
                    isOn: $settings.hapticsEnabled,
                    onImage: GameArt.vibraOn,
                    offImage: GameArt.vibraOff,
                    label: "Haptics"
                )
            }
            .frame(maxWidth: .infinity)

            Toggle("Sound Effects", isOn: $settings.soundEffectsEnabled)
                .tint(PlayHubTheme.orange)

            VStack(alignment: .leading, spacing: 6) {
                Text("Sound Volume")
                    .font(.subheadline.bold())
                    .foregroundStyle(PlayHubTheme.ink)
                Slider(value: $settings.soundVolume, in: 0...1)
                    .tint(PlayHubTheme.orange)
            }
            .disabled(!settings.soundEffectsEnabled)

            Toggle("Background Music", isOn: $settings.musicEnabled)
                .tint(PlayHubTheme.sky)

            VStack(alignment: .leading, spacing: 6) {
                Text("Music Volume")
                    .font(.subheadline.bold())
                    .foregroundStyle(PlayHubTheme.ink)
                Slider(value: $settings.musicVolume, in: 0...1)
                    .tint(PlayHubTheme.sky)
            }
            .disabled(!settings.musicEnabled)

            Toggle("Haptics", isOn: $settings.hapticsEnabled)
                .tint(PlayHubTheme.mint)
        }
        .padding(16)
        .background(panelBackground)
    }

    private var defaultGameOptionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Default Game Options", systemImage: "slider.horizontal.3")
                .font(.title3.bold())
                .foregroundStyle(PlayHubTheme.ink)

            Picker("Tap Frenzy", selection: $settings.defaultTapPreset) {
                ForEach(TapFrenzyPreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }

            Picker("Light It Up", selection: $settings.defaultLightPreset) {
                ForEach(LightItUpPreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }

            Picker("Quiz Difficulty", selection: $settings.defaultQuizDifficulty) {
                ForEach(QuizDifficulty.allCases) { difficulty in
                    Text(difficulty.displayName).tag(difficulty)
                }
            }

            Picker("Quiz Questions", selection: $settings.defaultQuizQuestionCount) {
                ForEach(GameSettingsStore.allowedQuestionCounts, id: \.self) { count in
                    Text("\(count)").tag(count)
                }
            }

            Picker("Quiz Category", selection: defaultCategoryBinding) {
                ForEach(settingsCategories) { category in
                    Text(category.name).tag(category.id)
                }
            }
        }
        .pickerStyle(.menu)
        .padding(16)
        .background(panelBackground)
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
        .background(panelBackground)
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
        .background(panelBackground)
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
        .background(panelBackground)
    }

    private var panelBackground: some View {
        PlayHubPanelBackground()
    }

    private func artToggleButton(
        isOn: Binding<Bool>,
        onImage: String,
        offImage: String,
        label: String
    ) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            VStack(spacing: 4) {
                Image(isOn.wrappedValue ? onImage : offImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)

                Text(label)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(PlayHubTheme.ink)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(isOn.wrappedValue ? "On" : "Off")
    }

    private var defaultCategoryBinding: Binding<Int> {
        Binding(
            get: { settings.defaultQuizCategoryID ?? TriviaCategory.anyID },
            set: { selectedID in
                if selectedID == TriviaCategory.anyID {
                    settings.setDefaultQuizCategory(id: nil, name: TriviaCategory.any.name)
                    return
                }
                guard let category = settingsCategories.first(where: { $0.id == selectedID }) else { return }
                settings.setDefaultQuizCategory(id: category.id, name: category.name)
            }
        )
    }

    private var settingsCategories: [TriviaCategory] {
        var categoryList = categories
        if let selectedID = settings.defaultQuizCategoryID,
           !categoryList.contains(where: { $0.id == selectedID }) {
            categoryList.append(TriviaCategory(id: selectedID, name: settings.defaultQuizCategoryName))
        }
        return categoryList
    }

    private func loadCategories() async {
        guard categories.count == 1 else { return }
        if let fetchedCategories = try? await TriviaAPI().fetchCategories() {
            categories = [.any] + fetchedCategories
        }
    }
}

#Preview {
    NavigationStack { SettingsTab() }
        .environmentObject(GameSessionStore.shared)
        .environmentObject(GameSettingsStore.shared)
        .environmentObject(LocationService.shared)
}
