import Fluent
import Vapor
import Foundation

struct FavoriteResponseDTO: Content {
    var id: UUID?
    var coffeeTypeID: UUID?
    var coffeeType: CoffeeType?
    var createdAt: Date?
    
    init(from favorite: Favorite, coffeeType: CoffeeType? = nil) {
        self.id = favorite.id
        self.coffeeTypeID = favorite.$coffeeType.id
        self.coffeeType = coffeeType
        self.createdAt = favorite.createdAt
    }
}

