import SwiftUI

struct ClientsView: View {
    @State private var clients: [Client] = []
    @State private var isLoading = true
    @State private var searchText = ""

    private var filtered: [Client] {
        guard !searchText.isEmpty else { return clients }
        let q = searchText.lowercased()
        return clients.filter {
            $0.name.lowercased().contains(q) ||
            $0.phone.contains(q) ||
            $0.dni.contains(q)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Text("Clientes")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(clients.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppColors.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppColors.primary.opacity(0.15))
                        .clipShape(Capsule())
                }

                // Search
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textSecondary)
                    TextField("Buscar cliente...", text: $searchText)
                        .foregroundColor(.white)
                        .textInputAutocapitalization(.never)
                }
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if isLoading {
                    ProgressView().tint(.white).padding(.top, 40)
                } else if filtered.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.textTertiary)
                        Text(searchText.isEmpty ? "Sin clientes aún" : "Sin resultados")
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(filtered) { client in
                        ClientCard(client: client)
                    }
                }
            }
            .padding(20)
        }
        .task { await load() }
    }

    private func load() async {
        do { clients = try await APIService.shared.listClients() } catch {}
        isLoading = false
    }
}

struct ClientCard: View {
    let client: Client

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(String(client.name.prefix(1)).uppercased())
                    .font(.headline)
                    .foregroundColor(AppColors.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(client.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                HStack(spacing: 8) {
                    Label(client.phone, systemImage: "phone")
                    Text("·")
                    Text("DNI: \(client.dni)")
                }
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(client.totalBookings)")
                    .font(.title3.bold())
                    .foregroundColor(AppColors.primary)
                Text("turnos")
                    .font(.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(14)
        .glassCard()
    }
}
