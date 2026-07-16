import SwiftUI

struct SettingsTab: View {
    @EnvironmentObject private var store: GameSessionStore
    @EnvironmentObject private var settings: GameSettingsStore
    @EnvironmentObject private var locationService: LocationService
    @StateObject private var notificationService = NotificationService.shared
    @State private var confirmReset = false
    @State private var categories: [TriviaCategory] = [.any]

    var body: some View {
        ZStack {
            MiniArcadeScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    settingsHeader
                    backgroundSection
                    audioSection
                    defaultGameOptionsSection
                    notificationSection
                    locationSection
                    resetSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 108)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(MiniArcadeTheme.wood, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .confirmationDialog("Reset all MiNi ARCADE stats?", isPresented: $confirmReset, titleVisibility: .visible) {
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

    private var settingsHeader: some View {
        HStack(spacing: 14) {
            Image(GameArt.settings)
                .resizable()
                .scaledToFit()
                .frame(width: 58, height: 58)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("SETTINGS")
                    .font(MiniArcadeGameFont.display(26))
                    .foregroundStyle(MiniArcadeTheme.lime)
                Text("Tune every game your way.")
                    .font(MiniArcadeGameFont.label(12))
                    .foregroundStyle(MiniArcadeTheme.mutedInk)
            }

            Spacer()
        }
        .padding(15)
        .background(MiniArcadePanelBackground(cornerRadius: 22))
    }

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("AUDIO & FEEL", systemImage: "speaker.wave.2.fill")

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

            volumeControl(
                title: "Sound Volume",
                symbol: "speaker.wave.2.fill",
                value: $settings.soundVolume,
                tint: MiniArcadeTheme.orange,
                isEnabled: settings.soundEffectsEnabled
            )

            volumeControl(
                title: "Music Volume",
                symbol: "music.note",
                value: $settings.musicVolume,
                tint: MiniArcadeTheme.sky,
                isEnabled: settings.musicEnabled
            )
        }
        .padding(16)
        .background(panelBackground)
    }

    private var backgroundSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("BACKGROUND", systemImage: "photo.fill")

            HStack(spacing: 10) {
                ForEach(GameBackgroundTheme.allCases) { theme in
                    Button {
                        settings.selectedBackgroundTheme = theme
                    } label: {
                        VStack(spacing: 7) {
                            ZStack(alignment: .topTrailing) {
                                Image(theme.assetName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 104)
                                    .clipped()

                                if settings.selectedBackgroundTheme == theme {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20, weight: .black))
                                        .foregroundStyle(MiniArcadeTheme.lime, MiniArcadeTheme.wood)
                                        .padding(6)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(
                                        settings.selectedBackgroundTheme == theme ? MiniArcadeTheme.lime : MiniArcadeTheme.cream.opacity(0.34),
                                        lineWidth: settings.selectedBackgroundTheme == theme ? 3 : 1
                                    )
                            }

                            Text(theme.displayName)
                                .font(MiniArcadeGameFont.label(11))
                                .foregroundStyle(MiniArcadeTheme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(theme.displayName)
                    .accessibilityValue(settings.selectedBackgroundTheme == theme ? "Selected" : "Not selected")
                }
            }
        }
        .padding(16)
        .background(panelBackground)
    }

    private var defaultGameOptionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("DEFAULT GAME SETUP", systemImage: "slider.horizontal.3")

            optionPicker("Tap Frenzy", systemImage: "hand.tap.fill", selection: $settings.defaultTapPreset) {
                ForEach(TapFrenzyPreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }

            optionPicker("Light It Up", systemImage: "bolt.fill", selection: $settings.defaultLightPreset) {
                ForEach(LightItUpPreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }

            optionPicker("Quiz Difficulty", systemImage: "speedometer", selection: $settings.defaultQuizDifficulty) {
                ForEach(QuizDifficulty.allCases) { difficulty in
                    Text(difficulty.displayName).tag(difficulty)
                }
            }

            optionPicker("Quiz Questions", systemImage: "questionmark.bubble.fill", selection: $settings.defaultQuizQuestionCount) {
                ForEach(GameSettingsStore.allowedQuestionCounts, id: \.self) { count in
                    Text("\(count)").tag(count)
                }
            }

            optionPicker("Quiz Category", systemImage: "square.grid.2x2.fill", selection: defaultCategoryBinding) {
                ForEach(settingsCategories) { category in
                    Text(category.name).tag(category.id)
                }
            }
        }
        .padding(16)
        .background(panelBackground)
    }

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("DAILY CHALLENGE", systemImage: "bell.badge.fill")

            Toggle(
                "Notifications",
                isOn: Binding(
                    get: { notificationService.notificationsEnabled },
                    set: { notificationService.setNotificationsEnabled($0) }
                )
            )
            .font(MiniArcadeGameFont.label(14))
            .tint(MiniArcadeTheme.lime)
            .padding(12)
            .background(settingRowBackground)

            DatePicker(
                "Challenge Time",
                selection: Binding(
                    get: { notificationService.dailyChallengeTime },
                    set: { notificationService.setDailyChallengeTime($0) }
                ),
                displayedComponents: .hourAndMinute
            )
            .font(MiniArcadeGameFont.label(14))
            .tint(MiniArcadeTheme.lime)
            .padding(12)
            .background(settingRowBackground)
            .disabled(!notificationService.notificationsEnabled)

            Text(notificationService.permissionLabel)
                .font(.caption)
                .foregroundStyle(MiniArcadeTheme.mutedInk)
        }
        .padding(16)
        .background(panelBackground)
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("LOCATION", systemImage: "location.fill")

            Text(locationService.permissionLabel)
                .font(.subheadline)
                .foregroundStyle(MiniArcadeTheme.mutedInk)

            if let lastErrorMessage = locationService.lastErrorMessage {
                Text(lastErrorMessage)
                    .font(.caption)
                    .foregroundStyle(MiniArcadeTheme.berry)
            }

            Button {
                locationService.requestPermission()
            } label: {
                Label("Refresh Location", systemImage: "location.circle.fill")
            }
            .buttonStyle(MiniArcadeSecondaryButtonStyle())
        }
        .padding(16)
        .background(panelBackground)
    }

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("SAVED STATS", systemImage: "chart.bar.fill")

            Text("\(store.sessions.count) saved sessions")
                .font(.subheadline)
                .foregroundStyle(MiniArcadeTheme.mutedInk)

            Button(role: .destructive) {
                confirmReset = true
            } label: {
                Label("Reset All Stats", systemImage: "trash")
            }
            .buttonStyle(MiniArcadeSecondaryButtonStyle())
        }
        .padding(16)
        .background(panelBackground)
    }

    private var panelBackground: some View {
        MiniArcadePanelBackground()
    }

    private var settingRowBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(MiniArcadeTheme.woodLight.opacity(0.72))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(MiniArcadeTheme.lime.opacity(0.18), lineWidth: 1)
            }
    }

    private func sectionTitle(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 9) {
            MiniArcadeSymbolIcon(
                systemName: systemImage,
                tint: MiniArcadeTheme.lime,
                size: 32,
                symbolSize: 14
            )

            Text(title)
                .font(MiniArcadeGameFont.display(16))
                .foregroundStyle(MiniArcadeTheme.lime)
        }
        .accessibilityAddTraits(.isHeader)
    }

    private func volumeControl(
        title: String,
        symbol: String,
        value: Binding<Double>,
        tint: Color,
        isEnabled: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: symbol)
                .font(MiniArcadeGameFont.label(13))
                .foregroundStyle(MiniArcadeTheme.ink)

            Slider(value: value, in: 0...1)
                .tint(tint)
        }
        .padding(12)
        .background(settingRowBackground)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.48)
    }

    private func optionPicker<SelectionValue: Hashable, Content: View>(
        _ title: String,
        systemImage: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(MiniArcadeGameFont.label(13))
                .foregroundStyle(MiniArcadeTheme.ink)

            Spacer(minLength: 6)

            Picker(selection: selection) {
                content()
            } label: {
                EmptyView()
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .tint(MiniArcadeTheme.lime)
        }
        .padding(12)
        .background(settingRowBackground)
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
                    .foregroundStyle(MiniArcadeTheme.ink)

                Text(isOn.wrappedValue ? "ON" : "OFF")
                    .font(MiniArcadeGameFont.label(9))
                    .foregroundStyle(MiniArcadeTheme.wood)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(isOn.wrappedValue ? MiniArcadeTheme.lime : MiniArcadeTheme.sand, in: Capsule())
            }
            .frame(maxWidth: .infinity)
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
