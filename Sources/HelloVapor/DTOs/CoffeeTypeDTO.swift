import Fluent
import Vapor
import Foundation

struct CoffeeTypeDTO: Content {
    var id: UUID?
    var name: String?
    var description: String?
    var price: Double?
    var imageURL: String?
    var isAvailable: Bool?
    var createdAt: Date?
    var updatedAt: Date?
    
    func toModel() -> CoffeeType {
        let model = CoffeeType()
        model.id = self.id
        if let name = self.name {
            model.name = name
        }
        if let description = self.description {
            model.description = description
        }
        if let price = self.price {
            model.price = price
        }
        if let imageURL = self.imageURL {
            model.imageURL = imageURL
        }
        if let isAvailable = self.isAvailable {
            model.isAvailable = isAvailable
        }
        return model
    }
}

