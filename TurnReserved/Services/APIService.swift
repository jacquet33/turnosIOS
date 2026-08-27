import Foundation

actor APIService {
    static let shared = APIService()

    #if DEBUG
    private let baseURL = "https://turnreserved.com/api"
    #else
    private let baseURL = "https://turnreserved.com/api"
    #endif

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    // MARK: - Generic Request

    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: Encodable? = nil,
        authenticated: Bool = true
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authenticated, let token = KeychainService.shared.getToken() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            req.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            if let err = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.server(err.error)
            }
            throw APIError.httpError(http.statusCode)
        }

        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Auth

    func register(email: String, phone: String, password: String) async throws -> RegisterResponse {
        try await request(
            path: "/auth/register",
            method: "POST",
            body: ["email": email, "phone": phone, "password": password],
            authenticated: false
        )
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        try await request(
            path: "/auth/login",
            method: "POST",
            body: ["email": email, "password": password],
            authenticated: false
        )
    }

    func googleAuth(credential: String) async throws -> AuthResponse {
        try await request(
            path: "/auth/google",
            method: "POST",
            body: ["credential": credential],
            authenticated: false
        )
    }

    func me() async throws -> MeResponse {
        try await request(path: "/auth/me")
    }

    // MARK: - Services

    func listServices() async throws -> [Service] {
        try await request(path: "/services")
    }

    func createService(name: String, minAdvanceHours: Int = 0) async throws -> Service {
        try await request(
            path: "/services",
            method: "POST",
            body: ["name": name, "minAdvanceHours": minAdvanceHours]
        )
    }

    func updateService(id: String, name: String, minAdvanceHours: Int = 0) async throws -> MessageResponse {
        try await request(
            path: "/services/\(id)",
            method: "PUT",
            body: ["name": name, "minAdvanceHours": minAdvanceHours]
        )
    }

    func deleteService(id: String) async throws -> MessageResponse {
        try await request(path: "/services/\(id)", method: "DELETE")
    }

    func getSchedule(serviceId: String) async throws -> ScheduleResponse {
        try await request(path: "/services/\(serviceId)/schedule")
    }

    func saveSchedule(serviceId: String, schedule: ServiceSchedule, dayConfig: DayConfigMap) async throws -> MessageResponse {
        try await request(
            path: "/services/\(serviceId)/schedule",
            method: "PUT",
            body: ["schedule": schedule, "dayConfig": dayConfig]
        )
    }

    // MARK: - Bookings

    func listBookings(date: String? = nil, status: String? = nil, serviceId: String? = nil) async throws -> [Booking] {
        var params: [String] = []
        if let date { params.append("date=\(date)") }
        if let status { params.append("status=\(status)") }
        if let serviceId { params.append("serviceId=\(serviceId)") }
        let qs = params.isEmpty ? "" : "?\(params.joined(separator: "&"))"
        return try await request(path: "/bookings\(qs)")
    }

    func updateBookingStatus(id: String, status: String) async throws -> StatusUpdateResponse {
        try await request(
            path: "/bookings/\(id)/status",
            method: "PATCH",
            body: ["status": status]
        )
    }

    // MARK: - Public Booking

    func getBookingPage(linkId: String) async throws -> BookingPage {
        try await request(path: "/book/\(linkId)", authenticated: false)
    }

    func createBooking(linkId: String, payload: BookingPayload) async throws -> BookingCreateResponse {
        try await request(
            path: "/book/\(linkId)",
            method: "POST",
            body: payload,
            authenticated: false
        )
    }

    // MARK: - Clients

    func listClients() async throws -> [Client] {
        try await request(path: "/clients")
    }

    // MARK: - Subscription

    func getSubscriptionStatus() async throws -> SubscriptionStatusResponse {
        try await request(path: "/subscription/status")
    }

    func createPreference(plan: String) async throws -> PreferenceResponse {
        try await request(
            path: "/subscription/create-preference",
            method: "POST",
            body: ["plan": plan]
        )
    }

    func cancelSubscription() async throws -> MessageResponse {
        try await request(path: "/subscription/cancel", method: "POST")
    }

    // MARK: - Offer

    func getOffer() async throws -> OfferResponse {
        try await request(path: "/offer")
    }
}

// MARK: - Error Types

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL inválida"
        case .invalidResponse: return "Respuesta inválida del servidor"
        case .httpError(let code): return "Error HTTP: \(code)"
        case .server(let msg): return msg
        }
    }
}

private struct ErrorResponse: Codable {
    let error: String
}

// MARK: - AnyEncodable helper

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        _encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
