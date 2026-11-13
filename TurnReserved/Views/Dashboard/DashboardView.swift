import SwiftUI

enum DashboardTab: String, CaseIterable {
    case services = "Servicios"
    case agenda = "Agenda"
    case clients = "Clientes"
    case profile = "Perfil"

    var icon: String {
        switch self {
        case .services: return "briefcase"
        case .agenda: return "calendar"
        case .clients: return "person.2"
        case .profile: return "mappin.circle"
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var selectedTab: DashboardTab = .services
    @State private var showExplore = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TurnReserved")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        if let user = auth.user {
                            Text(user.plan == .trial ? "Prueba gratuita" : "Plan \(user.plan.rawValue)")
                                .font(.caption)
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }

                    Spacer()

                    Button { showExplore = true } label: {
                        Image(systemName: "map")
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .accessibilityLabel("Explorar el mapa")

                    Button { auth.logout() } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)

                // Trial Banner
                if let user = auth.user, user.subscriptionStatus == .trial {
                    TrialBannerView(user: user)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }

                // Content
                TabView(selection: $selectedTab) {
                    ServicesView()
                        .tag(DashboardTab.services)
                    AgendaView()
                        .tag(DashboardTab.agenda)
                    ClientsView()
                        .tag(DashboardTab.clients)
                    PublicProfileView()
                        .tag(DashboardTab.profile)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Tab Bar
                HStack(spacing: 0) {
                    ForEach(DashboardTab.allCases, id: \.self) { tab in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 20))
                                Text(tab.rawValue)
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(selectedTab == tab ? AppColors.primary : AppColors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial.opacity(0.5))
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .fullScreenCover(isPresented: $showExplore) {
            ExploreView(accountLabel: "Mi panel") { showExplore = false }
        }
    }
}

struct TrialBannerView: View {
    let user: User

    private var daysLeft: Int {
        guard let ends = user.trialEndsAt else { return 0 }
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = fmt.date(from: ends) else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock")
                .foregroundColor(AppColors.warning)
            Text("Prueba gratuita: \(daysLeft) días restantes")
                .font(.caption.weight(.medium))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(12)
        .background(AppColors.warning.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.warning.opacity(0.2), lineWidth: 1)
        )
    }
}
