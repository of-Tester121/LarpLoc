import SwiftUI
import CoreLocation
import UserNotifications

struct FakePlace: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var subtitle: String
    var latitude: Double
    var longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    var coordText: String { String(format: "%.4f°, %.4f°", latitude, longitude) }
}

final class AppState: ObservableObject {
    // 0 = onboarding, 1 = permissions, 2 = main
    @Published var stage: Int { didSet { UserDefaults.standard.set(stage, forKey: "stage") } }
    @Published var name: String { didSet { UserDefaults.standard.set(name, forKey: "name") } }
    @Published var vibe: String { didSet { UserDefaults.standard.set(vibe, forKey: "vibe") } }
    @Published var reason: String { didSet { UserDefaults.standard.set(reason, forKey: "reason") } }
    @Published var dream: String { didSet { UserDefaults.standard.set(dream, forKey: "dream") } }
    @Published var drift: Bool { didSet { UserDefaults.standard.set(drift, forKey: "drift") } }
    @Published var current: FakePlace? { didSet { Self.save(current, "current") } }
    @Published var favorites: [FakePlace] { didSet { Self.save(favorites, "favorites") } }
    @Published var recents: [FakePlace] { didSet { Self.save(recents, "recents") } }

    init() {
        let d = UserDefaults.standard
        stage = d.integer(forKey: "stage")
        name = d.string(forKey: "name") ?? ""
        vibe = d.string(forKey: "vibe") ?? ""
        reason = d.string(forKey: "reason") ?? ""
        dream = d.string(forKey: "dream") ?? ""
        drift = d.bool(forKey: "drift")
        current = Self.load("current")
        favorites = Self.load("favorites") ?? []
        recents = Self.load("recents") ?? []
    }

    static func save<T: Encodable>(_ value: T, _ key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load<T: Decodable>(_ key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func setCurrent(_ p: FakePlace) {
        current = p
        recents.removeAll { sameSpot($0, p) }
        recents.insert(p, at: 0)
        if recents.count > 15 { recents = Array(recents.prefix(15)) }
    }

    func isFav(_ p: FakePlace) -> Bool { favorites.contains { sameSpot($0, p) } }

    func toggleFav(_ p: FakePlace) {
        if isFav(p) { favorites.removeAll { sameSpot($0, p) } } else { favorites.insert(p, at: 0) }
    }

    private func sameSpot(_ a: FakePlace, _ b: FakePlace) -> Bool {
        abs(a.latitude - b.latitude) < 0.0001 && abs(a.longitude - b.longitude) < 0.0001
    }
}

final class PermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published var notifGranted = false
    @Published var realLocation: CLLocation?
    private let manager = CLLocationManager()

    var locationGranted: Bool {
        locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways
    }

    override init() {
        super.init()
        manager.delegate = self
        locationStatus = manager.authorizationStatus
        if locationGranted { manager.startUpdatingLocation() }
        UNUserNotificationCenter.current().getNotificationSettings { s in
            DispatchQueue.main.async { self.notifGranted = (s.authorizationStatus == .authorized) }
        }
    }

    func requestLocation() { manager.requestWhenInUseAuthorization() }

    func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { self.notifGranted = granted }
        }
    }

    func notify(title: String, body: String) {
        guard notifGranted else { return }
        let c = UNMutableNotificationContent()
        c.title = title
        c.body = body
        c.sound = .default
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: c,
                                        trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        UNUserNotificationCenter.current().add(req)
    }

    func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        locationStatus = m.authorizationStatus
        if locationGranted { m.startUpdatingLocation() }
    }

    func locationManager(_ m: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        realLocation = locations.last
    }

    func locationManager(_ m: CLLocationManager, didFailWithError error: Error) {}
}
