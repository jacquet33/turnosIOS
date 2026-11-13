import SwiftUI
import MapKit
import CoreLocation

/// Pestaña "Perfil" del panel del negocio: datos públicos y ubicación en el mapa de la app.
struct PublicProfileView: View {
    @State private var profile: PublicProfile?
    @State private var groups: [CategoryGroup] = []
    @State private var region = MKCoordinateRegion(
        center: .init(latitude: -34.6037, longitude: -58.3816),
        latitudinalMeters: 1500, longitudinalMeters: 1500)
    @State private var pinAdjusted = false
    /// Centro fijado por código; solo un movimiento real (>15 m) cuenta como ajuste del pin
    @State private var anchorCenter: CLLocationCoordinate2D?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var message: String?
    @State private var messageIsError = false

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView().tint(.white).padding(.top, 60)
            } else if profile != nil {
                VStack(alignment: .leading, spacing: 16) {
                    listingToggle
                    section("Tu negocio") {
                        InputField(icon: "storefront", placeholder: "Nombre del negocio", text: binding(\.businessName))
                        categoryPicker
                        TextField("Descripción breve (qué hacés, especialidades)",
                                  text: binding(\.description), axis: .vertical)
                            .lineLimit(2...4)
                            .foregroundColor(.white)
                            .padding(14)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        InputField(icon: "message", placeholder: "WhatsApp público (opcional)",
                                   text: binding(\.publicPhone), keyboardType: .phonePad)
                    }
                    section("Ubicación") {
                        InputField(icon: "mappin.and.ellipse", placeholder: "Calle y número", text: binding(\.address))
                        HStack(spacing: 10) {
                            InputField(icon: "building.2", placeholder: "Ciudad", text: binding(\.city))
                            InputField(icon: "map", placeholder: "Provincia", text: binding(\.province))
                        }
                        locationMap
                    }
                    if let message {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(messageIsError ? AppColors.destructive : AppColors.success)
                    }
                    saveButton
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .task { await load() }
    }

    // MARK: - Secciones

    private var listingToggle: some View {
        Toggle(isOn: binding(\.isListed)) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Aparecer en el mapa").font(.headline).foregroundColor(.white)
                Text("Los clientes te encuentran por rubro y ciudad en la app")
                    .font(.caption).foregroundColor(AppColors.textSecondary)
            }
        }
        .tint(AppColors.primary)
        .padding(16)
        .glassCard()
    }

    private var categoryPicker: some View {
        Menu {
            ForEach(groups) { g in
                Section(g.name) {
                    ForEach(g.categories) { c in
                        Button { profile?.category = c.id } label: { Label(c.name, systemImage: c.sfSymbol) }
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "tag").foregroundColor(AppColors.textSecondary).frame(width: 20)
                Text(categoryName ?? "Elegí tu rubro")
                    .foregroundColor(categoryName == nil ? AppColors.textTertiary : .white)
                Spacer()
                Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var categoryName: String? {
        guard let id = profile?.category else { return nil }
        return groups.flatMap(\.categories).first { $0.id == id }?.name
    }

    private var locationMap: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                Map(coordinateRegion: Binding(
                    get: { region },
                    set: { newValue in
                        region = newValue
                        if let anchor = anchorCenter,
                           CLLocation(latitude: anchor.latitude, longitude: anchor.longitude)
                            .distance(from: CLLocation(latitude: newValue.center.latitude,
                                                       longitude: newValue.center.longitude)) > 15 {
                            pinAdjusted = true
                        }
                    }))
                Image(systemName: "mappin")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(AppColors.destructive)
                    .offset(y: -17)
                    .allowsHitTesting(false)
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Text(pinAdjusted
                 ? "Usaremos la posición del pin."
                 : "Guardá para ubicar la dirección automáticamente, o mové el mapa para ajustar el pin.")
                .font(.caption2)
                .foregroundColor(AppColors.textSecondary)
        }
    }

    private var saveButton: some View {
        Button { Task { await save() } } label: {
            HStack {
                if isSaving { ProgressView().tint(.white) } else { Text("Guardar perfil") }
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .background(AppColors.primaryGradient)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .disabled(isSaving)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundColor(AppColors.textSecondary)
            content()
        }
    }

    private func binding<T>(_ keyPath: WritableKeyPath<PublicProfile, T>) -> Binding<T> {
        Binding(get: { profile![keyPath: keyPath] }, set: { profile![keyPath: keyPath] = $0 })
    }

    // MARK: - Datos

    private func load() async {
        isLoading = true
        async let cats = try? APIService.shared.exploreCategories()
        do {
            let p = try await APIService.shared.getProfile()
            profile = p
            setRegion(p)
        } catch {
            message = error.localizedDescription
            messageIsError = true
        }
        groups = await cats ?? []
        isLoading = false
    }

    private func setRegion(_ p: PublicProfile) {
        pinAdjusted = false
        if let lat = p.lat, let lng = p.lng {
            region = MKCoordinateRegion(center: .init(latitude: lat, longitude: lng),
                                        latitudinalMeters: 800, longitudinalMeters: 800)
        }
        anchorCenter = region.center
    }

    private func save() async {
        guard let p = profile else { return }
        isSaving = true
        message = nil
        defer { isSaving = false }
        do {
            let updated = try await APIService.shared.updateProfile(ProfileUpdate(
                businessName: p.businessName, category: p.category, description: p.description,
                address: p.address, city: p.city, province: p.province,
                publicPhone: p.publicPhone, isListed: p.isListed,
                lat: pinAdjusted ? region.center.latitude : nil,
                lng: pinAdjusted ? region.center.longitude : nil))
            profile = updated
            setRegion(updated)
            if let warning = updated.geocodeWarning {
                message = warning
                messageIsError = true
            } else {
                message = updated.isListed ? "¡Listo! Ya aparecés en el mapa." : "Perfil guardado."
                messageIsError = false
            }
        } catch {
            message = error.localizedDescription
            messageIsError = true
        }
    }
}
