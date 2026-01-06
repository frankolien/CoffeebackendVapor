import Fluent
import Vapor
import Foundation

struct OrderCreateDTO: Content {
    var coffeeTypeID: UUID
    var locationID: UUID
    var quantity: Int
    var size: String?
    var milkType: String?
    var extras: String?
    var specialInstructions: String?
}

struct OrderUpdateDTO: Content {
    var status: OrderStatus?
    var size: String?
    var milkType: String?
    var extras: String?
    var specialInstructions: String?
}

struct OrderResponseDTO: Content {
    var id: UUID?
    var userID: UUID?
    var coffeeTypeID: UUID?
    var coffeeTypeName: String?
    var locationID: UUID?
    var locationName: String?
    var quantity: Int?
    var totalPrice: Double?
    var status: OrderStatus?
    var size: String?
    var milkType: String?
    var extras: String?
    var specialInstructions: String?
    var createdAt: Date?
    var updatedAt: Date?
    
    init(from order: Order, coffeeType: CoffeeType? = nil, location: Location? = nil) {
        self.id = order.id
        self.userID = order.$user.id
        self.coffeeTypeID = order.$coffeeType.id
        self.locationID = order.$location.id
        self.quantity = order.quantity
        self.totalPrice = order.totalPrice
        self.status = order.status
        self.size = order.size
        self.milkType = order.milkType
        self.extras = order.extras
        self.specialInstructions = order.specialInstructions
        self.createdAt = order.createdAt
        self.updatedAt = order.updatedAt
        
        if let coffeeType = coffeeType {
            self.coffeeTypeName = coffeeType.name
        }
        if let location = location {
            self.locationName = location.name
        }
    }
}

