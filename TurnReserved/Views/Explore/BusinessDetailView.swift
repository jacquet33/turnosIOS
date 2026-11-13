import SwiftUI
import MapKit

struct BusinessDetailView: View {
    let business: Business
    @State private var bookingLinkId: String?

    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerCard
                    if !business.description.isEmpty {
                        Text(business.description)
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    actions
                    servicesSection
                    miniMap
                }
                .padding(20)
            }
        }
        .navigationTitle(business.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .navigationDestination(isPresented: Binding(
            get: { bookingLinkId != nil },
            set: { if !$0 { bookingLinkId = nil } }
        )) {
            if let linkId = bookingLinkId {
                BookingScreen(linkId: linkId)
            }
        }
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            Image(systemName: BusinessCategory.groupSymbol(business.group))
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color(BusinessAnnotationView.color(for: business.group)))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(business.name).font(.title3.bold()).foregroundColor(.white)
                Text(business.fullAddress).font(.caption).foregroundColor(AppColors.textSecondary)
                if let d = business.distanceText {
                    Label("A \(d)", systemImage: "figure.walk").font(.caption).foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button { openDirections() } label: {
                Label("Cómo llegar", systemImage: "arrow.triangle.turn.up.right.diamond")
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
            }
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if let phone = business.phone, let url = whatsappURL(phone) {
                Link(destination: url) {
                    Label("WhatsApp", systemImage: "message")
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                }
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundColor(.white)
    }

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reservá un turno").font(.headline).foregroundColor(.white)
            if business.services.isEmpty {
                Text("Este lugar todavía no tiene servicios disponibles.")
                    .font(.caption).foregroundColor(AppColors.textSecondary)
            }
            ForEach(business.services, id: \.linkId) { svc in
                Button { bookingLinkId = svc.linkId } label: {
                    HStack {
                        Text(svc.name).foregroundColor(.white)
                        Spacer()
                        Text("Ver horarios")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppColors.primary)
                        Image(systemName: "chevron.right").font(.caption).foregroundColor(AppColors.textTertiary)
                    }
                    .padding(16)
                    .glassCard()
                }
            }
        }
    }

    private var miniMap: some View {
        Map(coordinateRegion: .constant(MKCoordinateRegion(center: business.coordinate,
                                                           latitudinalMeters: 600, longitudinalMeters: 600)),
            interactionModes: [],
            annotationItems: [business]) { b in
            MapMarker(coordinate: b.coordinate, tint: Color(BusinessAnnotationView.color(for: b.group)))
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture { openDirections() }
    }

    private func openDirections() {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: business.coordinate))
        item.name = business.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
    }

    private func whatsappURL(_ phone: String) -> URL? {
        var digits = phone.filter(\.isNumber)
        guard digits.count >= 8 else { return nil }
        if !digits.hasPrefix("54") { digits = "549" + digits } // Argentina por defecto
        return URL(string: "https://wa.me/\(digits)")
    }
}

/// Reutiliza el flujo de reserva pública existente dentro de la navegación.
private struct BookingScreen: View {
    let linkId: String
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        PublicBookingView(linkId: linkId, onBack: { dismiss() })
            .navigationTitle("Reservar")
            .navigationBarTitleDisplayMode(.inline)
    }
}
