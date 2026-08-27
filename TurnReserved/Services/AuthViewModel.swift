import Foundation
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var needsSubscription = false

    private let api = APIService.shared
    private let keychain = KeychainService.shared

    init() {
        Task { await checkSession() }
    }

    func checkSession() async {
        guard let token = keychain.getToken(),
              let savedUser = keychain.getUser() else {
            isLoading = false
            return
        }

        do {
            let fresh = try await api.me()
            if let id = fresh.id, !id.isEmpty {
                var updated = savedUser
                if let plan = fresh.plan { updated.plan = User.Plan(rawValue: plan) ?? savedUser.plan }
                if let status = fresh.subscription_status {
                    updated.subscriptionStatus = User.SubscriptionStatus(rawValue: status) ?? savedUser.subscriptionStatus
                }
                updated.trialEndsAt = fresh.trial_ends_at
                updated.subscriptionEndsAt = fresh.subscription_ends_at
                if let ms = fresh.max_services { updated.maxServices = ms }

                keychain.saveUser(updated)
                user = updated
                isAuthenticated = true
                needsSubscription = updated.subscriptionStatus == .expired || updated.subscriptionStatus == .cancelled
            } else {
                logout()
            }
        } catch {
            user = savedUser
            isAuthenticated = true
        }
        isLoading = false
    }

    func login(email: String, password: String) async throws {
        let response = try await api.login(email: email, password: password)
        handleAuth(response)
    }

    func register(email: String, phone: String, password: String) async throws {
        _ = try await api.register(email: email, phone: phone, password: password)
    }

    func googleLogin(credential: String) async throws {
        let response = try await api.googleAuth(credential: credential)
        handleAuth(response)
    }

    func logout() {
        keychain.clearAll()
        user = nil
        isAuthenticated = false
        needsSubscription = false
    }

    func refreshUser() async {
        await checkSession()
    }

    private func handleAuth(_ response: AuthResponse) {
        keychain.saveToken(response.token)
        keychain.saveUser(response.user)
        user = response.user
        isAuthenticated = true
        needsSubscription = response.user.subscriptionStatus == .expired || response.user.subscriptionStatus == .cancelled
    }
}
