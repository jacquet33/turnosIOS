import Foundation
import CoreLocation

// MARK: - Rubros

struct CategoryGroup: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let categories: [BusinessCategory]
}

struct BusinessCategory: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String

    /// Traduce el ícono genérico del backend a un SF Symbol (iOS 16+)
    var sfSymbol: String { BusinessCategory.symbol(for: icon) }

    static func symbol(for icon: String) -> String {
        switch icon {
        case "scissors":    return "scissors"
        case "mustache":    return "mustache"
        case "hand":        return "hand.raised"
        case "sparkles":    return "sparkles"
        case "leaf":        return "leaf"
        case "eye":         return "eye"
        case "stethoscope": return "stethoscope"
        case "tooth":       return "mouth"
        case "figure":      return "figure.walk"
        case "apple":       return "carrot"
        case "brain":       return "brain.head.profile"
        case "briefcase":   return "briefcase"
        case "family":      return "figure.2.and.child.holdinghands"
        case "shield":      return "shield"
        case "doc":         return "doc.text"
        case "pension":     return "banknote"
        case "scroll":      return "scroll"
        case "car":         return "car"
        case "stamp":       return "seal"
        default:            return "mappin"
        }
    }

    static func groupSymbol(_ groupId: String?) -> String {
        switch groupId {
        case "belleza": return "scissors"
        case "salud":   return "cross.case"
        case "legal":   return "building.columns"
        default:        return "mappin"
        }
    }
}

// MARK: - Negocios

struct PublicService: Codable, Hashable {
    let name: String
    let linkId: String
}

struct Business: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String?
    let group: String?
    let description: String
    let address: String
    let city: String
    let province: String
    let lat: Double
    let lng: Double
    let phone: String?
    let photoUrl: String?
    let distanceKm: Double?
    let services: [PublicService]

    var coordinate: CLLocationCoordinate2D { .init(latitude: lat, longitude: lng) }

    var fullAddress: String {
        [address, city, province].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    var distanceText: String? {
        guard let d = distanceKm else { return nil }
        return d < 1 ? "\(Int(d * 1000)) m" : String(format: "%.1f km", d)
    }
}

struct ExploreResponse: Codable {
    let radiusKm: Double
    let count: Int
    let results: [Business]
}

struct CityResult: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let province: String?
    let department: String?
    let lat: Double
    let lng: Double

    var label: String { [name, province].compactMap { $0 }.joined(separator: ", ") }
}

// MARK: - Perfil público del negocio (dueño)

struct PublicProfile: Codable {
    var publicId: String?
    var businessName: String
    var category: String?
    var description: String
    var address: String
    var city: String
    var province: String
    var lat: Double?
    var lng: Double?
    var publicPhone: String
    var photoUrl: String
    var isListed: Bool
    var geocodeWarning: String?
}

struct ProfileUpdate: Encodable {
    let businessName: String
    let category: String?
    let description: String
    let address: String
    let city: String
    let province: String
    let publicPhone: String
    let isListed: Bool
    /// Solo se envían si el dueño ajustó el pin; si van nil el servidor geocodifica la dirección
    let lat: Double?
    let lng: Double?

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(businessName, forKey: .businessName)
        try c.encodeIfPresent(category, forKey: .category)
        try c.encode(description, forKey: .description)
        try c.encode(address, forKey: .address)
        try c.encode(city, forKey: .city)
        try c.encode(province, forKey: .province)
        try c.encode(publicPhone, forKey: .publicPhone)
        try c.encode(isListed, forKey: .isListed)
        try c.encodeIfPresent(lat, forKey: .lat)
        try c.encodeIfPresent(lng, forKey: .lng)
    }

    enum CodingKeys: String, CodingKey {
        case businessName, category, description, address, city, province, publicPhone, isListed, lat, lng
    }
}
