import MapKit
import SwiftUI

struct MapTab: View {
    @EnvironmentObject private var store: GameSessionStore
    @EnvironmentObject private var locationService: LocationService

    @State private var selectedPinID: UUID?
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
            span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18)
        )
    )

    private var pins: [SessionMapPin] {
        store.sessions.compactMap { session in
            guard let coordinate = session.coordinate else { return nil }
            return SessionMapPin(session: session, coordinate: coordinate)
        }
    }

    private var selectedPin: SessionMapPin? {
        guard let selectedPinID else { return nil }
        return pins.first { $0.id == selectedPinID }
    }

    var body: some View {
        ZStack {
            MiniArcadeScreenBackground()

            if pins.isEmpty {
                emptyMapState
            } else {
                Map(position: $cameraPosition, selection: $selectedPinID) {
                    ForEach(pins) { pin in
                        Marker(
                            "\(pin.session.mode.displayName) \(pin.session.displayVariantLabel) \(pin.session.score)",
                            systemImage: pin.session.mode.symbolName,
                            coordinate: pin.coordinate
                        )
                        .tint(MiniArcadeTheme.tint(for: pin.session.mode))
                        .tag(pin.id)
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .safeAreaInset(edge: .bottom) {
                    if let selectedPin {
                        selectedPinCard(selectedPin)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 10)
                    }
                }
            }
        }
        .navigationTitle("Map")
        .toolbar {
            Button {
                locationService.refreshLocation()
            } label: {
                Image(systemName: "location.fill")
                    .accessibilityLabel("Refresh Location")
            }
        }
        .onAppear {
            locationService.requestPermission()
            focusOnFirstPinIfNeeded()
        }
        .onChange(of: pins.count) { _, _ in
            focusOnFirstPinIfNeeded()
        }
    }

    private var emptyMapState: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 58, weight: .black))
                .foregroundStyle(MiniArcadeTheme.berry)

            Text("No Map Pins Yet")
                .font(.title2.bold())
                .foregroundStyle(MiniArcadeTheme.ink)

            Text("Complete a game after location permission is enabled. Scores still save even when location is unavailable.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(MiniArcadeTheme.mutedInk)
                .padding(.horizontal, 28)

            Text(locationService.permissionLabel)
                .font(.caption.bold())
                .foregroundStyle(MiniArcadeTheme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.92), in: Capsule())

            Button {
                locationService.requestPermission()
            } label: {
                Label("Enable Location", systemImage: "location.fill")
            }
            .buttonStyle(MiniArcadePrimaryButtonStyle(tint: MiniArcadeTheme.berry))
            .padding(.horizontal, 24)
        }
        .padding(24)
    }

    private func selectedPinCard(_ pin: SessionMapPin) -> some View {
        HStack(spacing: 12) {
            MiniArcadeSymbolIcon(
                systemName: pin.session.mode.symbolName,
                tint: MiniArcadeTheme.tint(for: pin.session.mode),
                size: 44,
                symbolSize: 19
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(pin.session.mode.displayName)
                    .font(.headline)
                    .foregroundStyle(MiniArcadeTheme.ink)
                Text(pin.session.displayVariantLabel)
                    .font(.caption)
                    .foregroundStyle(MiniArcadeTheme.mutedInk)
                    .lineLimit(1)
                Text(pin.session.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(MiniArcadeTheme.mutedInk)
            }

            Spacer()

            Text("\(pin.session.score)")
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(MiniArcadeTheme.ink)
        }
        .padding(14)
        .background(MiniArcadePanelBackground())
    }

    private func focusOnFirstPinIfNeeded() {
        guard selectedPinID == nil, let first = pins.first else { return }
        selectedPinID = first.id
        cameraPosition = .region(
            MKCoordinateRegion(
                center: first.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
            )
        )
    }
}

private struct SessionMapPin: Identifiable {
    let session: GameSession
    let coordinate: CLLocationCoordinate2D

    var id: UUID { session.id }
}

#Preview {
    NavigationStack { MapTab() }
        .environmentObject(GameSessionStore.shared)
        .environmentObject(GameSettingsStore.shared)
        .environmentObject(LocationService.shared)
}
