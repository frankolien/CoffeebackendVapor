import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    try app.register(collection: AuthController())
    try app.register(collection: CoffeeTypeController())
    try app.register(collection: LocationController())
    try app.register(collection: OrderController())
    try app.register(collection: ReviewController())
    try app.register(collection: FavoriteController())
    try app.register(collection: LocationHoursController())
}
