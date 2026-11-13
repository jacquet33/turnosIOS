import SwiftUI
import MapKit

/// MKMapView envuelto para SwiftUI (iOS 16+). MapKit es gratis y sin API key.
/// - Muestra un pin por negocio, coloreado según el rubro, con clustering.
/// - Avisa cuando el usuario mueve el mapa, para ofrecer "Buscar en esta zona".
struct BusinessMapView: UIViewRepresentable {
    let businesses: [Business]
    @Binding var selectedId: String?
    /// Cambiarlo mueve la cámara (p. ej. al elegir ciudad o al centrar en mi ubicación)
    let cameraTarget: MapCameraTarget?
    let onRegionChanged: (MKCoordinateRegion, _ byUser: Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.pointOfInterestFilter = .excludingAll
        map.overrideUserInterfaceStyle = .dark
        map.register(BusinessAnnotationView.self,
                     forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        map.register(MKMarkerAnnotationView.self,
                     forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.parent = self

        // Sincronizar anotaciones sin recrear las que no cambiaron
        let current = map.annotations.compactMap { $0 as? BusinessAnnotation }
        let currentIds = Set(current.map(\.business.id))
        let newIds = Set(businesses.map(\.id))
        map.removeAnnotations(current.filter { !newIds.contains($0.business.id) })
        map.addAnnotations(businesses.filter { !currentIds.contains($0.id) }.map(BusinessAnnotation.init))

        // Selección
        if let id = selectedId,
           let ann = map.annotations.compactMap({ $0 as? BusinessAnnotation }).first(where: { $0.business.id == id }),
           !map.selectedAnnotations.contains(where: { $0 === ann }) {
            map.selectAnnotation(ann, animated: true)
        }

        // Cámara
        if let target = cameraTarget, target.id != context.coordinator.lastCameraId {
            context.coordinator.lastCameraId = target.id
            context.coordinator.programmaticMove = true
            map.setRegion(MKCoordinateRegion(center: target.center,
                                             latitudinalMeters: target.radiusKm * 2000,
                                             longitudinalMeters: target.radiusKm * 2000),
                          animated: context.coordinator.hasInitialRegion)
            context.coordinator.hasInitialRegion = true
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: BusinessMapView
        var lastCameraId: UUID?
        var programmaticMove = false
        var hasInitialRegion = false

        init(_ parent: BusinessMapView) { self.parent = parent }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            let byUser = !programmaticMove
            programmaticMove = false
            parent.onRegionChanged(mapView.region, byUser)
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let ann = view.annotation as? BusinessAnnotation {
                parent.selectedId = ann.business.id
            } else if let cluster = view.annotation as? MKClusterAnnotation {
                mapView.showAnnotations(cluster.memberAnnotations, animated: true)
                mapView.deselectAnnotation(cluster, animated: false)
            }
        }
    }
}

struct MapCameraTarget: Equatable {
    let id = UUID()
    let center: CLLocationCoordinate2D
    let radiusKm: Double

    static func == (a: Self, b: Self) -> Bool { a.id == b.id }
}

final class BusinessAnnotation: NSObject, MKAnnotation {
    let business: Business
    var coordinate: CLLocationCoordinate2D { business.coordinate }
    var title: String? { business.name }
    init(_ business: Business) { self.business = business }
}

final class BusinessAnnotationView: MKMarkerAnnotationView {
    override var annotation: MKAnnotation? {
        didSet { configure() }
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "business"
        displayPriority = .defaultHigh
        configure()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func configure() {
        guard let ann = annotation as? BusinessAnnotation else { return }
        markerTintColor = BusinessAnnotationView.color(for: ann.business.group)
        glyphImage = UIImage(systemName: BusinessCategory.groupSymbol(ann.business.group))
    }

    static func color(for group: String?) -> UIColor {
        switch group {
        case "belleza": return UIColor(red: 0.91, green: 0.33, blue: 0.62, alpha: 1)
        case "salud":   return UIColor(red: 0.13, green: 0.70, blue: 0.55, alpha: 1)
        case "legal":   return UIColor(red: 0.85, green: 0.65, blue: 0.20, alpha: 1)
        default:        return UIColor(red: 0, green: 0.41, blue: 0.80, alpha: 1)
        }
    }
}
