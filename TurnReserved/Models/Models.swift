import Foundation

// MARK: - User & Auth

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let phone: String
    var plan: Plan
    var subscriptionStatus: SubscriptionStatus
    var trialEndsAt: String?
    var subscriptionEndsAt: String?
    var maxServices: Int

    enum Plan: String, Codable {
        case trial, basic, pro, business
    }

    enum SubscriptionStatus: String, Codable {
        case trial, active, expired, cancelled
    }
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct RegisterResponse: Codable {
    let message: String
}

struct MeResponse: Codable {
    let id: String?
    let plan: String?
    let subscription_status: String?
    let trial_ends_at: String?
    let subscription_ends_at: String?
    let max_services: Int?
}

// MARK: - Service

struct Service: Codable, Identifiable {
    let id: String
    let name: String
    let linkId: String
    let hasSchedule: Bool
    let minAdvanceHours: Int
    let createdAt: String
}

// MARK: - Schedule

struct DaySchedule: Codable {
    let enabled: Bool
    let slots: [String]
}

struct DayConfig: Codable {
    let startTime: String
    let endTime: String
    let duration: Int
}

typealias ServiceSchedule = [String: DaySchedule]
typealias DayConfigMap = [String: DayConfig]

struct ScheduleResponse: Codable {
    let schedule: ServiceSchedule
    let dayConfig: DayConfigMap
}

// MARK: - Booking

struct Booking: Codable, Identifiable {
    let id: String
    let serviceId: String
    let serviceName: String
    let clientName: String
    let clientDNI: String
    let clientPhone: String
    let date: String
    let time: String
    let status: BookingStatus
    let createdAt: String

    enum BookingStatus: String, Codable {
        case pending, completed, cancelled
    }
}

struct BookingSlot: Codable {
    let id: String
    let date: String
    let time: String
    let status: String
}

struct BookingPage: Codable {
    let service: BookingService
    let schedule: ServiceSchedule
    let dayConfig: DayConfigMap
    let bookedSlots: [BookingSlot]

    struct BookingService: Codable {
        let id: String
        let name: String
        let minAdvanceHours: Int
    }
}

struct BookingPayload: Codable {
    let name: String
    let dni: String
    let phone: String
    let date: String
    let time: String
}

struct BookingCreateResponse: Codable {
    let id: String
    let status: String
}

// MARK: - Subscription

struct SubscriptionStatusResponse: Codable {
    let plan: String
    let status: String
    let maxServices: Int
    let trialEndsAt: String?
    let subscriptionEndsAt: String?
    let daysLeft: Int?
}

struct PreferenceResponse: Codable {
    let preferenceId: String
    let initPoint: String
    let sandboxUrl: String
}

// MARK: - Client

struct Client: Codable, Identifiable {
    var id: String { "\(name)-\(dni)" }
    let name: String
    let phone: String
    let dni: String
    let totalBookings: Int
    let lastBooking: String
}

// MARK: - Offer

struct OfferResponse: Codable {
    let active: Bool
    let expiresAt: String?
    let discountPct: Int?
    let months: Int?
}

// MARK: - Generic

struct MessageResponse: Codable {
    let message: String
}

struct StatusUpdateResponse: Codable {
    let message: String
    let status: String
}

// MARK: - Plan Info

struct PlanInfo {
    let name: String
    let price: Int
    let maxServices: Int
    let days: Int?

    static let plans: [String: PlanInfo] = [
        "trial":    PlanInfo(name: "Free Trial", price: 0,  maxServices: 3,  days: 5),
        "basic":    PlanInfo(name: "Basic",      price: 9,  maxServices: 1,  days: nil),
        "pro":      PlanInfo(name: "Pro",        price: 19, maxServices: 3,  days: nil),
        "business": PlanInfo(name: "Business",   price: 39, maxServices: -1, days: nil),
    ]
}
