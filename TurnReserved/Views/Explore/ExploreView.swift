import SwiftUI
import MapKit

/// Pantalla principal en modo cliente: mapa + filtros por rubro + tarjetas de negocios.
struct ExploreView: View {
    /// Texto y acción del botón superior derecho ("Soy profesional" o "Mi panel")
    var accountLabel: String = "Soy profesional"
    var onAccount: () -> Void

    @StateObject private var vm = ExploreViewModel()
    @State private var showCitySearch = false
    @State private var showList = false
    @State private var path: [Business] = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .top) {
                BusinessMapView(
                    businesses: vm.results,
                    selectedId: $vm.selectedId,
                    cameraTarget: vm.cameraTarget,
                    onRegionChanged: { region, byUser in
                        Task { @MainActor in vm.regionChanged(region, byUser: byUser) }
                    }
                )
                .ignoresSafeArea()

                VStack(spacing: 10) {
                    header
                    groupChips
                    if !vm.subcategories.isEmpty { subcategoryChips }
                    if vm.showSearchHere { searchHereButton }
                    if let err = vm.error { errorBanner(err) }
                    Spacer()
                    bottomCards
                }
                .padding(.top, 4)
            }
            .navigationDestination(for: Business.self) { business in
                BusinessDetailView(business: business)
            }
            .sheet(isPresented: $showCitySearch) { citySheet }
            .sheet(isPresented: $showList) { listSheet }
            .task { await vm.start() }
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(AppColors.primary)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Button { showCitySearch = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Buscar en").font(.caption2).foregroundColor(AppColors.textSecondary)
                        Text(vm.placeLabel).font(.subheadline.weight(.semibold)).lineLimit(1)
                    }
                    Spacer()
                    if vm.isLoading { ProgressView().scaleEffect(0.8).tint(.white) }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button { Task { await vm.centerOnUser() } } label: {
                Image(systemName: "location.fill")
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .accessibilityLabel("Mi ubicación")

            Button(action: onAccount) {
                Image(systemName: "person.crop.circle")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(AppColors.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .accessibilityLabel(accountLabel)
        }
        .padding(.horizontal, 16)
    }

    private var groupChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(title: "Todos", icon: "square.grid.2x2", selected: vm.selectedGroup == nil) {
                    vm.selectedGroup = nil
                }
                ForEach(vm.groups) { g in
                    Chip(title: g.name, icon: BusinessCategory.groupSymbol(g.id), selected: vm.selectedGroup == g.id) {
                        vm.selectedGroup = vm.selectedGroup == g.id ? nil : g.id
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var subcategoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.subcategories) { c in
                    Chip(title: c.name, icon: c.sfSymbol, selected: vm.selectedCategory == c.id, small: true) {
                        vm.selectedCategory = vm.selectedCategory == c.id ? nil : c.id
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var searchHereButton: some View {
        Button { vm.searchHere() } label: {
            Label("Buscar en esta zona", systemImage: "arrow.clockwise")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(AppColors.primary)
                .clipShape(Capsule())
                .shadow(radius: 6)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func errorBanner(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.white)
            .padding(10)
            .background(AppColors.destructive.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 16)
            .onTapGesture { vm.error = nil }
    }

    // MARK: - Tarjetas inferiores

    private var bottomCards: some View {
        VStack(spacing: 8) {
            HStack {
                Text(vm.results.isEmpty ? "Sin resultados en esta zona" :
                        "\(vm.results.count) lugar\(vm.results.count == 1 ? "" : "es") para reservar")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.white)
                Spacer()
                if !vm.results.isEmpty {
                    Button("Ver lista") { showList = true }.font(.footnote.weight(.semibold))
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding(.horizontal, 16)

            if !vm.results.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(vm.results) { b in
                                BusinessCard(business: b, highlighted: vm.selectedId == b.id)
                                    .id(b.id)
                                    .onTapGesture { path.append(b) }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .onChange(of: vm.selectedId) { id in
                        guard let id else { return }
                        withAnimation { proxy.scrollTo(id, anchor: .center) }
                    }
                }
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Sheets

    private var citySheet: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showCitySearch = false
                        Task { await vm.centerOnUser() }
                    } label: { Label("Usar mi ubicación", systemImage: "location.fill") }
                }
                Section {
                    TextField("Ej: Colón, Paraná, Rosario…", text: $vm.cityQuery)
                        .autocorrectionDisabled()
                        .onChange(of: vm.cityQuery) { _ in vm.cityQueryChanged() }
                    ForEach(vm.cityResults) { city in
                        Button {
                            vm.choose(city: city)
                            showCitySearch = false
                        } label: {
                            VStack(alignment: .leading) {
                                Text(city.name).foregroundColor(.primary)
                                Text([city.department, city.province].compactMap { $0 }.joined(separator: ", "))
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                } header: { Text("Ciudad") }
                Section {
                    TextField("Nombre del lugar o servicio", text: $vm.query)
                        .onSubmit {
                            vm.submitQuery()
                            showCitySearch = false
                        }
                } header: { Text("Buscar por nombre") }
            }
            .navigationTitle("¿Dónde buscás?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showCitySearch = false }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var listSheet: some View {
        NavigationStack {
            List(vm.results) { b in
                Button {
                    showList = false
                    path.append(b)
                } label: { BusinessRow(business: b) }
            }
            .navigationTitle(vm.placeLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { showList = false } }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Componentes

private struct Chip: View {
    let title: String
    let icon: String
    let selected: Bool
    var small = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(small ? .caption.weight(.medium) : .subheadline.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, small ? 10 : 14)
                .padding(.vertical, small ? 6 : 9)
                .background(selected ? AnyShapeStyle(AppColors.primary) : AnyShapeStyle(.ultraThinMaterial))
                .clipShape(Capsule())
        }
    }
}

struct BusinessCard: View {
    let business: Business
    var highlighted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: BusinessCategory.groupSymbol(business.group))
                    .foregroundColor(Color(BusinessAnnotationView.color(for: business.group)))
                Text(business.name).font(.headline).foregroundColor(.white).lineLimit(1)
            }
            Text(business.fullAddress).font(.caption).foregroundColor(AppColors.textSecondary).lineLimit(1)
            HStack {
                if let d = business.distanceText {
                    Label(d, systemImage: "figure.walk").font(.caption2).foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                Text("Reservar")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(AppColors.primary)
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .frame(width: 270)
        .background(.ultraThinMaterial)
        .background(AppColors.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(highlighted ? AppColors.primary : AppColors.cardBorder, lineWidth: highlighted ? 2 : 1))
    }
}

struct BusinessRow: View {
    let business: Business
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: BusinessCategory.groupSymbol(business.group))
                .foregroundColor(Color(BusinessAnnotationView.color(for: business.group)))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(business.name).font(.body.weight(.semibold)).foregroundColor(.primary)
                Text(business.fullAddress).font(.caption).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
            if let d = business.distanceText { Text(d).font(.caption).foregroundColor(.secondary) }
        }
    }
}
