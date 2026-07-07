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
            PlayHubScreenBackground()

            if pins.isEmpty {
                emptyMapState
            } else {
                Map(position: $cameraPosition, selection: $selectedPinID) {
                    ForEach(pins) { pin in
                        Marker(
                            "\(pin.session.mode.displayName) \(pin.session.score)",
                            systemImage: pin.session.mode.symbolName,
                            coordinate: pin.coordinate
                        )
                        .tint(PlayHubTheme.tint(for: pin.session.mode))
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
                .foregroundStyle(PlayHubTheme.berry)

            Text("No Map Pins Yet")
                .font(.title2.bold())
                .foregroundStyle(PlayHubTheme.ink)

            Text("Complete a game after location permission is enabled. Scores still save even when location is unavailable.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(PlayHubTheme.mutedInk)
                .padding(.horizontal, 28)

            Text(locationService.permissionLabel)
                .font(.caption.bold())
                .foregroundStyle(PlayHubTheme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.92), in: Capsule())

            Button {
                locationService.requestPermission()
            } label: {
                Label("Enable Location", systemImage: "location.fill")
            }
            .buttonStyle(PlayHubPrimaryButtonStyle(tint: PlayHubTheme.berry))
            .padding(.horizontal, 24)
        }
        .padding(24)
    }

    private func selectedPinCard(_ pin: SessionMapPin) -> some View {
        HStack(spacing: 12) {
            Image(systemName: pin.session.mode.symbolName)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(PlayHubTheme.tint(for: pin.session.mode), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(pin.session.mode.displayName)
                    .font(.headline)
                    .foregroundStyle(PlayHubTheme.ink)
                Text(pin.session.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(PlayHubTheme.mutedInk)
            }

            Spacer()

            Text("\(pin.session.score)")
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(PlayHubTheme.ink)
        }
        .padding(14)
        .background(Color.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 8)
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
        .environmentObject(LocationService.shared)
}
