import Fluent
import Vapor
import Foundation

struct FavoriteController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let favorites = routes.grouped("favorites")
            .grouped(JWTAuthenticator())
        
        favorites.get(use: self.index)
        favorites.get(":coffeeTypeID", use: self.check)
        favorites.post(":coffeeTypeID", use: self.create)
        favorites.delete(":coffeeTypeID", use: self.delete)
    }
    
    func index(req: Request) async throws -> [FavoriteResponseDTO] {
        let user = try req.auth.require(User.self)
        
        let favorites = try await Favorite.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .with(\.$coffeeType)
            .all()
        
        var result: [FavoriteResponseDTO] = []
        for favorite in favorites {
            let coffeeType = try await favorite.$coffeeType.get(on: req.db)
            result.append(FavoriteResponseDTO(from: favorite, coffeeType: coffeeType))
        }
        return result
    }
    
    func check(req: Request) async throws -> [String: Bool] {
        let user = try req.auth.require(User.self)
        
        guard let coffeeTypeID = req.parameters.get("coffeeTypeID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        let favorite = try await Favorite.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .filter(\.$coffeeType.$id == coffeeTypeID)
            .first()
        
        return ["isFavorite": favorite != nil]
    }
    
    func create(req: Request) async throws -> FavoriteResponseDTO {
        let user = try req.auth.require(User.self)
        
        guard let coffeeTypeID = req.parameters.get("coffeeTypeID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        guard let _ = try await CoffeeType.find(coffeeTypeID, on: req.db) else {
            throw Abort(.notFound, reason: "Coffee type not found")
        }
        
        let existing = try await Favorite.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .filter(\.$coffeeType.$id == coffeeTypeID)
            .first()
        
        if existing != nil {
            throw Abort(.conflict, reason: "Already favorited")
        }
        
        let favorite = Favorite(userID: user.id!, coffeeTypeID: coffeeTypeID)
        try await favorite.save(on: req.db)
        
        let coffeeType = try await favorite.$coffeeType.get(on: req.db)
        return FavoriteResponseDTO(from: favorite, coffeeType: coffeeType)
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard let coffeeTypeID = req.parameters.get("coffeeTypeID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        guard let favorite = try await Favorite.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .filter(\.$coffeeType.$id == coffeeTypeID)
            .first() else {
            throw Abort(.notFound)
        }
        
        try await favorite.delete(on: req.db)
        return .noContent
    }
}

