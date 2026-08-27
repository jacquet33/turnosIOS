import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var isSignup = false
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var error = ""
    @State private var success = ""

    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Logo
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 48))
                            .foregroundStyle(AppColors.primaryGradient)

                        Text("TurnReserved")
                            .font(.title.bold())
                            .foregroundColor(.white)

                        Text(isSignup ? "Creá tu cuenta" : "Iniciá sesión")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, 60)

                    // Form
                    VStack(spacing: 16) {
                        InputField(
                            icon: "envelope",
                            placeholder: "Email",
                            text: $email,
                            keyboardType: .emailAddress
                        )

                        if isSignup {
                            InputField(
                                icon: "phone",
                                placeholder: "Celular",
                                text: $phone,
                                keyboardType: .phonePad
                            )
                        }

                        HStack {
                            InputField(
                                icon: "lock",
                                placeholder: "Contraseña",
                                text: $password,
                                isSecure: !showPassword
                            )
                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(AppColors.textSecondary)
                                    .frame(width: 44, height: 44)
                            }
                        }

                        if !error.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.circle")
                                Text(error)
                            }
                            .font(.caption)
                            .foregroundColor(AppColors.destructive)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if !success.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text(success)
                            }
                            .font(.caption)
                            .foregroundColor(AppColors.success)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            Task { await submit() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(isSignup ? "Crear cuenta" : "Iniciar sesión")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                        }
                        .background(AppColors.primaryGradient)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .disabled(isLoading)
                    }
                    .padding(24)
                    .glassCard()

                    // Toggle
                    Button {
                        withAnimation {
                            isSignup.toggle()
                            error = ""
                            success = ""
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(isSignup ? "¿Ya tenés cuenta?" : "¿No tenés cuenta?")
                                .foregroundColor(AppColors.textSecondary)
                            Text(isSignup ? "Iniciar sesión" : "Crear cuenta")
                                .foregroundColor(AppColors.primary)
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func submit() async {
        error = ""
        success = ""
        guard !email.isEmpty, !password.isEmpty else {
            error = "Completá todos los campos"
            return
        }
        if isSignup && phone.isEmpty {
            error = "El celular es requerido"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            if isSignup {
                try await auth.register(email: email, phone: phone, password: password)
                success = "✅ Cuenta creada. Tenés 5 días de prueba gratuita."
                withAnimation { isSignup = false }
            } else {
                try await auth.login(email: email, password: password)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Input Field

struct InputField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .textContentType(.password)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
