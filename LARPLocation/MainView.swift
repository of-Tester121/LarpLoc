import SwiftUI
import MapKit

final class SearchModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func update(_ query: String) {
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            results = []
        } else {
            completer.queryFragment = query
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {}
}

func parseCoordinates(_ s: String) -> CLLocationCoordinate2D? {
    let parts = s.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    guard parts.count == 2,
          let la = Double(parts[0]), let lo = Double(parts[1]),
          (-90.0...90.0).contains(la), (-180.0...180.0).contains(lo) else { return nil }
    return CLLocationCoordinate2D(latitude: la, longitude: lo)
}

struct MainView: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var perms: PermissionManager
    @StateObject private var search = SearchModel()

    @State private var camera: MapCameraPosition = .automatic
    @State private var query = ""
    @FocusState private var searching: Bool
    @State private var pending: FakePlace?
    @State private var showSaved = false
    @State private var showProfile = false
    @State private var jitter = CGSize.zero

    private let timer = Timer.publish(every: 2.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .top) {
            MapReader { proxy in
                Map(position: $camera) {
                    UserAnnotation()
                    if let c = app.current {
                        Annotation(c.name, coordinate: shifted(c.coordinate)) { PulseDot() }
                    }
                    if let p = pending, p.id != app.current?.id {
                        Marker(p.name, systemImage: "mappin", coordinate: p.coordinate).tint(.pink)
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .onTapGesture { point in
                    searching = false
                    if let coord = proxy.convert(point, from: .local) { pick(coordinate: coord) }
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 10) {
                topBar
                if searching && !query.isEmpty { suggestions }
                Spacer()
                bottomCard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showSaved) {
            SavedView { place in show(place) }
        }
        .sheet(isPresented: $showProfile) { ProfileView() }
        .onReceive(timer) { _ in
            guard app.drift, app.current != nil else { return }
            withAnimation(.easeInOut(duration: 2)) {
                jitter = CGSize(width: Double.random(in: -0.0004...0.0004),
                                height: Double.random(in: -0.0004...0.0004))
            }
        }
        .onAppear {
            if let c = app.current { fly(to: c.coordinate) }
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search or type 35.68, 139.69", text: $query)
                    .focused($searching)
                    .submitLabel(.search)
                    .onSubmit(submitSearch)
                    .onChange(of: query) { _, q in search.update(q) }
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 46)
            .glass(23)

            Button { showSaved = true } label: { Image(systemName: "star.fill") }
                .circleButton()
            Button { showProfile = true } label: { Image(systemName: "person.fill") }
                .circleButton()
        }
    }

    private var suggestions: some View {
        VStack(spacing: 0) {
            if let coord = parseCoordinates(query) {
                suggestionRow(title: "Use these coordinates", subtitle: query, icon: "scope") {
                    searching = false
                    pick(coordinate: coord)
                }
            }
            ForEach(Array(search.results.prefix(5).enumerated()), id: \.offset) { _, r in
                suggestionRow(title: r.title, subtitle: r.subtitle, icon: "mappin.circle.fill") {
                    choose(r)
                }
            }
        }
        .glass(18)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func suggestionRow(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundStyle(Color.neonPink)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                    if !subtitle.isEmpty {
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Bottom card

    @ViewBuilder
    private var bottomCard: some View {
        if let p = pending, p.id != app.current?.id {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(p.name).font(.title3.bold()).foregroundStyle(.white)
                        Text(p.subtitle.isEmpty ? p.coordText : p.subtitle)
                            .font(.footnote).foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    Button { app.toggleFav(p) } label: {
                        Image(systemName: app.isFav(p) ? "star.fill" : "star").foregroundStyle(.yellow)
                    }
                    Button { withAnimation(.spring()) { pending = nil } } label: {
                        Image(systemName: "xmark").foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.leading, 6)
                }
                Button { teleport(p) } label: {
                    Label("Teleport here", systemImage: "location.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(16)
            .glass(26)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else if let c = app.current {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Circle().fill(.green).frame(width: 8, height: 8)
                    Text("LARP ACTIVE").font(.caption.bold()).tracking(1.5).foregroundStyle(.green)
                }
                Text("📍 \(c.name)").font(.title2.bold()).foregroundStyle(.white)
                Text(c.subtitle.isEmpty ? c.coordText : "\(c.subtitle) · \(c.coordText)")
                    .font(.footnote).foregroundStyle(.white.opacity(0.7))
                HStack(spacing: 10) {
                    ShareLink(item: "📍 \(app.name.isEmpty ? "I'm" : app.name + " is") in \(c.name) rn 😎 (via LARP Location)") {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    Button(action: backToReality) {
                        Label("Back to reality", systemImage: "arrow.uturn.backward")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(16)
            .glass(26)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            Text("Tap the map or search to pick a place ✨")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18).padding(.vertical, 12)
                .glass(24)
                .transition(.opacity)
        }
    }

    // MARK: Actions

    private func shifted(_ c: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        guard app.drift else { return c }
        return CLLocationCoordinate2D(latitude: c.latitude + jitter.width, longitude: c.longitude + jitter.height)
    }

    private func fly(to c: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 1.4)) {
            camera = .camera(MapCamera(centerCoordinate: c, distance: 6000, heading: 0, pitch: 40))
        }
    }

    private func show(_ p: FakePlace) {
        searching = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { pending = p }
        fly(to: p.coordinate)
    }

    private func pick(coordinate c: CLLocationCoordinate2D) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let temp = FakePlace(name: "Dropped pin", subtitle: "", latitude: c.latitude, longitude: c.longitude)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { pending = temp }
        fly(to: c)
        Task {
            let loc = CLLocation(latitude: c.latitude, longitude: c.longitude)
            guard let pm = try? await CLGeocoder().reverseGeocodeLocation(loc).first else { return }
            let name = pm.name ?? pm.locality ?? "Dropped pin"
            let sub = [pm.locality, pm.administrativeArea, pm.country].compactMap { $0 }.joined(separator: ", ")
            await MainActor.run {
                if pending?.id == temp.id {
                    pending = FakePlace(id: temp.id, name: name, subtitle: sub, latitude: c.latitude, longitude: c.longitude)
                }
            }
        }
    }

    private func choose(_ r: MKLocalSearchCompletion) {
        query = r.title
        searching = false
        Task {
            guard let item = try? await MKLocalSearch(request: MKLocalSearch.Request(completion: r)).start().mapItems.first else { return }
            let co = item.placemark.coordinate
            let place = FakePlace(name: item.name ?? r.title, subtitle: r.subtitle, latitude: co.latitude, longitude: co.longitude)
            await MainActor.run { show(place) }
        }
    }

    private func submitSearch() {
        searching = false
        if let c = parseCoordinates(query) { pick(coordinate: c); return }
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = query
        Task {
            guard let item = try? await MKLocalSearch(request: req).start().mapItems.first else { return }
            let co = item.placemark.coordinate
            let sub = [item.placemark.locality, item.placemark.administrativeArea, item.placemark.country]
                .compactMap { $0 }.joined(separator: ", ")
            let place = FakePlace(name: item.name ?? query, subtitle: sub, latitude: co.latitude, longitude: co.longitude)
            await MainActor.run { show(place) }
        }
    }

    private func teleport(_ p: FakePlace) {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            app.setCurrent(p)
            pending = nil
        }
        fly(to: p.coordinate)
        perms.notify(title: "Teleported 📍", body: "You're now in \(p.name). Nobody has to know.")
    }

    private func backToReality() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring()) { app.current = nil }
        if let r = perms.realLocation {
            fly(to: r.coordinate)
        } else {
            withAnimation { camera = .userLocation(fallback: .automatic) }
        }
    }
}

// MARK: - Saved

struct SavedView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    var onPick: (FakePlace) -> Void

    var body: some View {
        NavigationStack {
            List {
                if app.favorites.isEmpty && app.recents.isEmpty {
                    Text("Nothing here yet. Star a place or teleport somewhere first.")
                        .foregroundStyle(.secondary)
                }
                if !app.favorites.isEmpty {
                    Section("Favorites") {
                        ForEach(app.favorites) { row($0) }
                            .onDelete { app.favorites.remove(atOffsets: $0) }
                    }
                }
                if !app.recents.isEmpty {
                    Section("Recent") {
                        ForEach(app.recents) { row($0) }
                    }
                }
            }
            .navigationTitle("Places")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }

    private func row(_ p: FakePlace) -> some View {
        Button {
            onPick(p)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(p.name).foregroundStyle(.primary)
                Text(p.subtitle.isEmpty ? p.coordText : p.subtitle)
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Profile

struct ProfileView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("You") {
                    TextField("Name", text: $app.name)
                    if !app.vibe.isEmpty { LabeledContent("Vibe", value: app.vibe) }
                    if !app.reason.isEmpty { LabeledContent("Why", value: app.reason) }
                    if !app.dream.isEmpty { LabeledContent("Dream spot", value: app.dream) }
                }
                Section {
                    Toggle("Live drift", isOn: $app.drift)
                } footer: {
                    Text("Makes your fake pin wobble a little so it looks like you're actually walking around.")
                }
                Section {
                    Button("Redo setup") {
                        app.stage = 0
                        dismiss()
                    }
                }
                Section("About") {
                    Text("LARP Location shows you at your chosen spot inside this app and in anything you share from it. It doesn't change your iPhone's real GPS, so other apps still see where you actually are.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }
}
