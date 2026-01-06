import Fluent
import Vapor
import Foundation

final class Favorite: Model, Content, @unchecked Sendable {
    static let schema = "favorites"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "coffee_type_id")
    var coffeeType: CoffeeType
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, userID: UUID, coffeeTypeID: UUID) {
        self.id = id
        self.$user.id = userID
        self.$coffeeType.id = coffeeTypeID
    }
}

