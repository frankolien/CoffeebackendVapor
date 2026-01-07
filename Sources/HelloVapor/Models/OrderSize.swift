import Foundation

enum OrderSize: String, Codable, Content {
    case small = "S"
    case medium = "M"
    case large = "L"
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
    
    var priceMultiplier: Double {
        switch self {
        case .small: return 0.9  // 10% discount for small
        case .medium: return 1.0  // Base price for medium
        case .large: return 1.2   // 20% premium for large
        }
    }
}

