import Foundation
import MapKit

@MainActor
final class ExploreViewModel: ObservableObject {
    // Datos
    @Published var groups: [CategoryGroup] = []
    @Published var results: [Business] = []
    @Published var selectedId: String?

    // Filtros
    @Published var selectedGroup: String? { didSet { if oldValue != selectedGroup { selectedCategory = nil; Task { await search() } } } }
    @Published var selectedCategory: String? { didSet { if oldValue != selectedCategory { Task { await search() } } } }
    @Published var query = ""

    // Mapa
    @Published var cameraTarget: MapCameraTarget?
    @Published var showSearchHere = false
    @Published private(set) var center = CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816) // CABA por defecto
    @Published private(set) var radiusKm: Double = 10
    @Published var placeLabel = "Cerca tuyo"

    // Ciudad
    @Published var cityQuery = ""
    @Published var cityResults: [CityResult] = []

    // Estado
    @Published var isLoading = false
    @Published var error: String?

    private var pendingRegion: MKCoordinateRegion?
    private var searchTask: Task<Void, Never>?
    private var cityTask: Task<Void, Never>?
    private var started = false

    var selectedBusiness: Business? { results.first { $0.id == selectedId } }

    var subcategories: [BusinessCategory] {
        groups.first { $0.id == selectedGroup }?.categories ?? []
    }

    func start() async {
        guard !started else { return }
        started = true
        async let cats: [CategoryGroup]? = try? APIService.shared.exploreCategories()
        let location = await LocationService.shared.currentLocation()
        groups = await cats ?? []
        if let location {
            move(to: location, radiusKm: 5, label: "Cerca tuyo")
        } else {
            placeLabel = "Elegí tu ciudad"
            move(to: center, radiusKm: 10, label: "Buenos Aires")
        }
    }

    func centerOnUser() async {
        if let location = await LocationService.shared.currentLocation() {
            move(to: location, radiusKm: 5, label: "Cerca tuyo")
        } else {
            error = "Activá la ubicación en Ajustes o buscá tu ciudad."
        }
    }

    func choose(city: CityResult) {
        cityQuery = ""
        cityResults = []
        move(to: .init(latitude: city.lat, longitude: city.lng), radiusKm: 8, label: city.label)
    }

    private func move(to coord: CLLocationCoordinate2D, radiusKm: Double, label: String) {
        center = coord
        self.radiusKm = radiusKm
        placeLabel = label
        showSearchHere = false
        cameraTarget = MapCameraTarget(center: coord, radiusKm: radiusKm)
        Task { await search() }
    }

    /// Llamado por el mapa. Si lo movió el usuario, ofrecemos "Buscar en esta zona" (estilo Mercado Libre).
    func regionChanged(_ region: MKCoordinateRegion, byUser: Bool) {
        guard byUser else { return }
        pendingRegion = region
        let moved = CLLocation(latitude: center.latitude, longitude: center.longitude)
            .distance(from: CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)) / 1000
        let newRadius = Self.radius(of: region)
        showSearchHere = moved > radiusKm * 0.3 || abs(newRadius - radiusKm) > radiusKm * 0.5
    }

    func searchHere() {
        guard let region = pendingRegion else { return }
        center = region.center
        radiusKm = Self.radius(of: region)
        placeLabel = "Esta zona"
        showSearchHere = false
        Task { await search() }
    }

    func submitQuery() {
        Task { await search() }
    }

    func search() async {
        searchTask?.cancel()
        let task = Task { [center, radiusKm, selectedGroup, selectedCategory, query] in
            isLoading = true
            defer { isLoading = false }
            do {
                let res = try await APIService.shared.explore(
                    lat: center.latitude, lng: center.longitude, radiusKm: radiusKm,
                    group: selectedGroup, category: selectedCategory,
                    query: query.trimmingCharacters(in: .whitespaces))
                guard !Task.isCancelled else { return }
                results = res.results
                if let id = selectedId, !res.results.contains(where: { $0.id == id }) { selectedId = nil }
                error = nil
            } catch {
                guard !Task.isCancelled else { return }
                self.error = error.localizedDescription
            }
        }
        searchTask = task
        await task.value
    }

    func cityQueryChanged() {
        cityTask?.cancel()
        let q = cityQuery.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { cityResults = []; return }
        cityTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000) // debounce
            guard !Task.isCancelled else { return }
            let list = (try? await APIService.shared.searchCities(q)) ?? []
            guard !Task.isCancelled else { return }
            cityResults = list
        }
    }

    static func radius(of region: MKCoordinateRegion) -> Double {
        // Mitad del lado más corto visible, en km (el backend lo limita a 50)
        let latKm = region.span.latitudeDelta * 111.32
        let lngKm = region.span.longitudeDelta * 111.32 * cos(region.center.latitude * .pi / 180)
        return min(max(min(latKm, lngKm) / 2, 0.5), 50)
    }
}
