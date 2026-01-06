import Fluent
import Vapor
import Foundation

struct CoffeeTypeController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let coffeeTypes = routes.grouped("coffee-types")
        
        coffeeTypes.get(use: self.index)
        coffeeTypes.get(":coffeeTypeID", use: self.show)
        
        let protected = coffeeTypes.grouped(JWTAuthenticator())
        protected.post(use: self.create)
        protected.put(":coffeeTypeID", use: self.update)
        protected.delete(":coffeeTypeID", use: self.delete)
    }
    
    func index(req: Request) async throws -> [CoffeeType] {
        var query = CoffeeType.query(on: req.db)
        
        if let availableOnly = req.query[Bool.self, at: "available"], availableOnly {
            query = query.filter(\.$isAvailable == true)
        }
        
        if let search = req.query[String.self, at: "search"] {
            query = query.group(.or) { or in
                or.filter(\.$name ~~ search)
                or.filter(\.$description ~~ search)
            }
        }
        
        if let minPrice = req.query[Double.self, at: "minPrice"] {
            query = query.filter(\.$price >= minPrice)
        }
        
        if let maxPrice = req.query[Double.self, at: "maxPrice"] {
            query = query.filter(\.$price <= maxPrice)
        }
        
        let sortBy = req.query[String.self, at: "sortBy"] ?? "name"
        let sortOrder = req.query[String.self, at: "sortOrder"] ?? "asc"
        
        switch sortBy {
        case "price":
            if sortOrder == "desc" {
                query = query.sort(\.$price, .descending)
            } else {
                query = query.sort(\.$price, .ascending)
            }
        case "name":
            if sortOrder == "desc" {
                query = query.sort(\.$name, .descending)
            } else {
                query = query.sort(\.$name, .ascending)
            }
        default:
            query = query.sort(\.$name, .ascending)
        }
        
        return try await query.all()
    }
    
    func show(req: Request) async throws -> CoffeeType {
        guard let coffeeType = try await CoffeeType.find(req.parameters.get("coffeeTypeID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return coffeeType
    }
    
    func create(req: Request) async throws -> CoffeeType {
        try await req.auth.require(User.self)
        
        let coffeeTypeDTO = try req.content.decode(CoffeeTypeDTO.self)
        
        guard let name = coffeeTypeDTO.name,
              let price = coffeeTypeDTO.price else {
            throw Abort(.badRequest, reason: "Name and price are required")
        }
        
        let coffeeType = CoffeeType(
            name: name,
            description: coffeeTypeDTO.description,
            price: price,
            imageURL: coffeeTypeDTO.imageURL,
            isAvailable: coffeeTypeDTO.isAvailable ?? true
        )
        
        try await coffeeType.save(on: req.db)
        return coffeeType
    }
    
    func update(req: Request) async throws -> CoffeeType {
        try await req.auth.require(User.self)
        
        guard let coffeeType = try await CoffeeType.find(req.parameters.get("coffeeTypeID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let coffeeTypeDTO = try req.content.decode(CoffeeTypeDTO.self)
        
        if let name = coffeeTypeDTO.name {
            coffeeType.name = name
        }
        if let description = coffeeTypeDTO.description {
            coffeeType.description = description
        }
        if let price = coffeeTypeDTO.price {
            coffeeType.price = price
        }
        if let imageURL = coffeeTypeDTO.imageURL {
            coffeeType.imageURL = imageURL
        }
        if let isAvailable = coffeeTypeDTO.isAvailable {
            coffeeType.isAvailable = isAvailable
        }
        
        try await coffeeType.save(on: req.db)
        return coffeeType
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        try await req.auth.require(User.self)
        
        guard let coffeeType = try await CoffeeType.find(req.parameters.get("coffeeTypeID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await coffeeType.delete(on: req.db)
        return .noContent
    }
}

