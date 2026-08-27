import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var isLoading = false

    private let plans: [(key: String, name: String, price: Int, features: [String])] = [
        ("basic", "Basic", 9, ["1 servicio", "Turnos ilimitados", "Link de reserva"]),
        ("pro", "Pro", 19, ["3 servicios", "Turnos ilimitados", "Link de reserva", "Gestión de clientes"]),
        ("business", "Business", 39, ["Servicios ilimitados", "Turnos ilimitados", "Todo incluido", "Soporte prioritario"]),
    ]

    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "crown")
                            .font(.system(size: 40))
                            .foregroundStyle(AppColors.warning)
                        Text("Tu suscripción expiró")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("Elegí un plan para continuar")
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, 40)

                    ForEach(plans, id: \.key) { plan in
                        PlanCard(
                            name: plan.name,
                            price: plan.price,
                            features: plan.features,
                            isPopular: plan.key == "pro"
                        ) {
                            Task { await subscribe(plan: plan.key) }
                        }
                    }

                    Button {
                        auth.logout()
                    } label: {
                        Text("Cerrar sesión")
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, 16)
                }
                .padding(20)
            }
        }
    }

    private func subscribe(plan: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let pref = try await APIService.shared.createPreference(plan: plan)
            if let url = URL(string: pref.initPoint) {
                await UIApplication.shared.open(url)
            }
        } catch {}
    }
}

struct PlanCard: View {
    let name: String
    let price: Int
    let features: [String]
    let isPopular: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if isPopular {
                Text("POPULAR")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(AppColors.primary)
                    .clipShape(Capsule())
            }

            Text(name)
                .font(.title3.bold())
                .foregroundColor(.white)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("$\(price)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                Text("/mes")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.success)
                            .font(.caption)
                        Text(feature)
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }

            Button(action: onSelect) {
                Text("Elegir plan")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .background(isPopular ? AppColors.primaryGradient : LinearGradient(colors: [Color.white.opacity(0.1)], startPoint: .leading, endPoint: .trailing))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(20)
        .glassCard()
        .overlay(
            isPopular ?
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.primary.opacity(0.4), lineWidth: 1) : nil
        )
    }
}
