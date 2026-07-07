import Combine
import CoreLocation
import Foundation

@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var currentCoordinate: CLLocationCoordinate2D?
    @Published private(set) var lastErrorMessage: String?

    private let manager = CLLocationManager()

    private override init() {
        super.init()
        authorizationStatus = manager.authorizationStatus
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var permissionLabel: String {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return "Location enabled"
        case .denied, .restricted:
            return "Location unavailable"
        case .notDetermined:
            return "Location not requested"
        @unknown default:
            return "Location status unknown"
        }
    }

    func requestPermission() {
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            refreshLocation()
        case .denied, .restricted:
            lastErrorMessage = "Enable location in Settings to place future scores on the map."
        @unknown default:
            break
        }
    }

    func refreshLocation() {
        guard isAuthorized else {
            requestPermission()
            return
        }
        manager.requestLocation()
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.authorizationStatus = status
            if self.isAuthorized {
                self.refreshLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let latestCoordinate = locations.last?.coordinate
        let latitude = latestCoordinate?.latitude
        let longitude = latestCoordinate?.longitude
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let latitude, let longitude {
                self.currentCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
            self.lastErrorMessage = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.lastErrorMessage = "Location could not be read for this session."
        }
    }
}
