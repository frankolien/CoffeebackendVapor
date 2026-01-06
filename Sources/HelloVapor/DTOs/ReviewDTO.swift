import Fluent
import Vapor
import Foundation

struct ReviewCreateDTO: Content, Validatable {
    var coffeeTypeID: UUID?
    var locationID: UUID?
    var rating: Int?
    var comment: String?
    
    static func validations(_ validations: inout Validations) {
        validations.add("rating", as: Int.self, is: .range(1...5))
    }
}

struct ReviewResponseDTO: Content {
    var id: UUID?
    var userID: UUID?
    var userName: String?
    var coffeeTypeID: UUID?
    var coffeeTypeName: String?
    var locationID: UUID?
    var locationName: String?
    var rating: Int?
    var comment: String?
    var createdAt: Date?
    
    init(from review: Review, user: User? = nil, coffeeType: CoffeeType? = nil, location: Location? = nil) {
        self.id = review.id
        self.userID = review.$user.id
        self.coffeeTypeID = review.$coffeeType.id
        self.locationID = review.$location.id
        self.rating = review.rating
        self.comment = review.comment
        self.createdAt = review.createdAt
        
        if let user = user {
            self.userName = user.fullName
        }
        if let coffeeType = coffeeType {
            self.coffeeTypeName = coffeeType.name
        }
        if let location = location {
            self.locationName = location.name
        }
    }
}

struct RatingSummaryDTO: Content {
    var averageRating: Double
    var totalReviews: Int
    var ratingDistribution: [Int: Int]
}

