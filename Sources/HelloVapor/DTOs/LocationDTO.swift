import Fluent
import Vapor
import Foundation

struct LocationDTO: Content {
    var id: UUID?
    var name: String?
    var address: String?
    var city: String?
    var state: String?
    var zipCode: String?
    var country: String?
    var latitude: Double?
    var longitude: Double?
    var phone: String?
    var isActive: Bool?
    var createdAt: Date?
    var updatedAt: Date?
    
    func toModel() -> Location {
        let model = Location()
        model.id = self.id
        if let name = self.name {
            model.name = name
        }
        if let address = self.address {
            model.address = address
        }
        if let city = self.city {
            model.city = city
        }
        if let state = self.state {
            model.state = state
        }
        if let zipCode = self.zipCode {
            model.zipCode = zipCode
        }
        if let country = self.country {
            model.country = country
        }
        if let latitude = self.latitude {
            model.latitude = latitude
        }
        if let longitude = self.longitude {
            model.longitude = longitude
        }
        if let phone = self.phone {
            model.phone = phone
        }
        if let isActive = self.isActive {
            model.isActive = isActive
        }
        return model
    }
}

