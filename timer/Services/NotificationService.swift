import Combine
import Foundation
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published private(set) var notificationsEnabled: Bool
    @Published private(set) var dailyChallengeTime: Date
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()
    private let enabledKey = "playhub.notificationsEnabled"
    private let timeKey = "playhub.dailyChallengeTime"
    private let requestID = "playhub.dailyChallenge"
    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.notificationsEnabled = defaults.bool(forKey: enabledKey)
        self.dailyChallengeTime = defaults.object(forKey: timeKey) as? Date ?? Self.defaultChallengeTime()
    }

    var permissionLabel: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Notifications allowed"
        case .denied:
            return "Notifications denied"
        case .notDetermined:
            return "Notifications not requested"
        @unknown default:
            return "Notification status unknown"
        }
    }

    func refreshAuthorization() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func setNotificationsEnabled(_ enabled: Bool) {
        if enabled {
            Task { await requestAndSchedule() }
        } else {
            notificationsEnabled = false
            defaults.set(false, forKey: enabledKey)
            center.removePendingNotificationRequests(withIdentifiers: [requestID])
        }
    }

    func setDailyChallengeTime(_ date: Date) {
        dailyChallengeTime = date
        defaults.set(date, forKey: timeKey)
        guard notificationsEnabled else { return }
        Task { await scheduleDailyChallenge() }
    }

    private func requestAndSchedule() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorization()
            notificationsEnabled = granted
            defaults.set(granted, forKey: enabledKey)
            if granted {
                await scheduleDailyChallenge()
            }
        } catch {
            notificationsEnabled = false
            defaults.set(false, forKey: enabledKey)
        }
    }

    private func scheduleDailyChallenge() async {
        center.removePendingNotificationRequests(withIdentifiers: [requestID])

        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: dailyChallengeTime)
        dateComponents.second = 0

        let content = UNMutableNotificationContent()
        content.title = "Game Arcade Daily Challenge"
        content.body = "Try one quick game and beat your best score."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)
        try? await center.add(request)
    }

    private static func defaultChallengeTime() -> Date {
        var components = DateComponents()
        components.hour = 18
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}
