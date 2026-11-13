import SwiftUI

/// Una sola app, dos modos:
///  - Sin sesión → modo cliente: mapa para buscar y reservar (ExploreView)
///  - Con sesión → modo negocio: panel con servicios, agenda, clientes y perfil público
struct RootView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var showLogin = false

    var body: some View {
        Group {
            if auth.isLoading {
                LoadingView()
            } else if !auth.isAuthenticated {
                ExploreView(accountLabel: "Soy profesional") { showLogin = true }
                    .sheet(isPresented: $showLogin) {
                        NavigationStack {
                            LoginView()
                                .toolbar {
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button("Cerrar") { showLogin = false }
                                    }
                                }
                        }
                    }
            } else if auth.needsSubscription {
                SubscriptionView()
            } else {
                DashboardView()
            }
        }
        .onChange(of: auth.isAuthenticated) { _ in showLogin = false }
        .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: auth.needsSubscription)
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            ProgressView()
                .tint(.white)
                .scaleEffect(1.2)
        }
    }
}
