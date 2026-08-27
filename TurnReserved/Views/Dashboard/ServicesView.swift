import SwiftUI

struct ServicesView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var services: [Service] = []
    @State private var isLoading = true
    @State private var showAdd = false
    @State private var newName = ""
    @State private var newAdvanceHours = ""
    @State private var editingService: Service?
    @State private var editName = ""
    @State private var error = ""
    @State private var showSchedule: Service?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Header
                HStack {
                    Text("Mis Servicios")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(AppColors.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.bottom, 8)

                if isLoading {
                    ProgressView().tint(.white).padding(.top, 40)
                } else if services.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "briefcase")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.textTertiary)
                        Text("No tenés servicios creados")
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(services) { service in
                        ServiceCard(
                            service: service,
                            onEdit: {
                                editingService = service
                                editName = service.name
                            },
                            onDelete: { Task { await deleteService(service) } },
                            onSchedule: { showSchedule = service }
                        )
                    }
                }
            }
            .padding(20)
        }
        .task { await loadServices() }
        .sheet(isPresented: $showAdd) { addSheet }
        .sheet(item: $editingService) { svc in editSheet(svc) }
        .sheet(item: $showSchedule) { svc in
            ScheduleConfigView(service: svc)
        }
    }

    private var addSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                InputField(icon: "briefcase", placeholder: "Nombre del servicio", text: $newName)
                InputField(icon: "clock", placeholder: "Horas mínimas de anticipación", text: $newAdvanceHours, keyboardType: .numberPad)

                if !error.isEmpty {
                    Text(error).font(.caption).foregroundColor(AppColors.destructive)
                }

                Button {
                    Task { await addService() }
                } label: {
                    Text("Crear servicio")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .background(AppColors.primaryGradient)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()
            }
            .padding(24)
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Nuevo Servicio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showAdd = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func editSheet(_ service: Service) -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                InputField(icon: "briefcase", placeholder: "Nombre", text: $editName)

                Button {
                    Task { await updateService(service) }
                } label: {
                    Text("Guardar")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .background(AppColors.primaryGradient)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()
            }
            .padding(24)
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Editar Servicio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { editingService = nil }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func loadServices() async {
        do {
            services = try await APIService.shared.listServices()
        } catch {}
        isLoading = false
    }

    private func addService() async {
        guard !newName.isEmpty else { error = "Nombre requerido"; return }
        do {
            let svc = try await APIService.shared.createService(
                name: newName,
                minAdvanceHours: Int(newAdvanceHours) ?? 0
            )
            services.append(svc)
            showAdd = false
            newName = ""
            newAdvanceHours = ""
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func updateService(_ service: Service) async {
        do {
            _ = try await APIService.shared.updateService(id: service.id, name: editName)
            await loadServices()
            editingService = nil
        } catch {}
    }

    private func deleteService(_ service: Service) async {
        do {
            _ = try await APIService.shared.deleteService(id: service.id)
            services.removeAll { $0.id == service.id }
        } catch {}
    }
}

// MARK: - Service Card

struct ServiceCard: View {
    let service: Service
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSchedule: () -> Void

    @State private var showCopied = false

    private var bookingURL: String {
        "https://turnreserved.com/book/\(service.linkId)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        Label(service.hasSchedule ? "Configurado" : "Sin horarios",
                              systemImage: service.hasSchedule ? "checkmark.circle" : "exclamationmark.circle")
                            .font(.caption)
                            .foregroundColor(service.hasSchedule ? AppColors.success : AppColors.warning)
                    }
                }

                Spacer()

                Menu {
                    Button { onSchedule() } label: {
                        Label("Configurar horarios", systemImage: "clock")
                    }
                    Button { onEdit() } label: {
                        Label("Editar", systemImage: "pencil")
                    }
                    Button {
                        UIPasteboard.general.string = bookingURL
                        showCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCopied = false
                        }
                    } label: {
                        Label("Copiar link", systemImage: "link")
                    }
                    Divider()
                    Button(role: .destructive) { onDelete() } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            if showCopied {
                Text("✓ Link copiado")
                    .font(.caption)
                    .foregroundColor(AppColors.success)
                    .transition(.opacity)
            }
        }
        .padding(16)
        .glassCard()
        .animation(.easeInOut, value: showCopied)
    }
}
