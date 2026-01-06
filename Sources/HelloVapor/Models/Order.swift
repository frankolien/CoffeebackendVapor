import Fluent
import Vapor
import Foundation

enum OrderStatus: String, Codable, Content {
    case pending
    case confirmed
    case preparing
    case ready
    case completed
    case cancelled
}

final class Order: Model, Content, @unchecked Sendable {
    static let schema = "orders"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "coffee_type_id")
    var coffeeType: CoffeeType
    
    @Parent(key: "location_id")
    var location: Location
    
    @Field(key: "quantity")
    var quantity: Int
    
    @Field(key: "total_price")
    var totalPrice: Double
    
    @Field(key: "status")
    var status: OrderStatus
    
    @Field(key: "size")
    var size: String?
    
    @Field(key: "milk_type")
    var milkType: String?
    
    @Field(key: "extras")
    var extras: String?
    
    @Field(key: "special_instructions")
    var specialInstructions: String?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, userID: UUID, coffeeTypeID: UUID, locationID: UUID, quantity: Int, totalPrice: Double, status: OrderStatus = .pending, size: String? = nil, milkType: String? = nil, extras: String? = nil, specialInstructions: String? = nil) {
        self.id = id
        self.$user.id = userID
        self.$coffeeType.id = coffeeTypeID
        self.$location.id = locationID
        self.quantity = quantity
        self.totalPrice = totalPrice
        self.status = status
        self.size = size
        self.milkType = milkType
        self.extras = extras
        self.specialInstructions = specialInstructions
    }
}

