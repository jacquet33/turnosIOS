import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        Group {
            if auth.isLoading {
                LoadingView()
            } else if !auth.isAuthenticated {
                LoginView()
            } else if auth.needsSubscription {
                SubscriptionView()
            } else {
                DashboardView()
            }
        }
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
