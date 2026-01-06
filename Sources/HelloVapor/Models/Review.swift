import Fluent
import Vapor
import Foundation

final class Review: Model, Content, @unchecked Sendable {
    static let schema = "reviews"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @OptionalParent(key: "coffee_type_id")
    var coffeeType: CoffeeType?
    
    @OptionalParent(key: "location_id")
    var location: Location?
    
    @Field(key: "rating")
    var rating: Int
    
    @Field(key: "comment")
    var comment: String?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, userID: UUID, coffeeTypeID: UUID? = nil, locationID: UUID? = nil, rating: Int, comment: String? = nil) {
        self.id = id
        self.$user.id = userID
        if let coffeeTypeID = coffeeTypeID {
            self.$coffeeType.id = coffeeTypeID
        }
        if let locationID = locationID {
            self.$location.id = locationID
        }
        self.rating = rating
        self.comment = comment
    }
}

