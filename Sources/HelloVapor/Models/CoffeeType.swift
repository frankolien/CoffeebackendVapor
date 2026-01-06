import Fluent
import Vapor
import Foundation

final class CoffeeType: Model, Content, @unchecked Sendable {
    static let schema = "coffee_types"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "description")
    var description: String?
    
    @Field(key: "price")
    var price: Double
    
    @Field(key: "image_url")
    var imageURL: String?
    
    @Field(key: "is_available")
    var isAvailable: Bool
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Children(for: \.$coffeeType)
    var orders: [Order]
    
    @Children(for: \.$coffeeType)
    var reviews: [Review]
    
    @Children(for: \.$coffeeType)
    var favorites: [Favorite]
    
    init() { }
    
    init(id: UUID? = nil, name: String, description: String? = nil, price: Double, imageURL: String? = nil, isAvailable: Bool = true) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.imageURL = imageURL
        self.isAvailable = isAvailable
    }
}

