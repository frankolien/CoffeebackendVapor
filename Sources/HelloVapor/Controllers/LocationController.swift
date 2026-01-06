import Fluent
import Vapor
import Foundation

struct LocationController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let locations = routes.grouped("locations")
        
        locations.get(use: self.index)
        locations.get(":locationID", use: self.show)
        
        let protected = locations.grouped(JWTAuthenticator())
        protected.post(use: self.create)
        protected.put(":locationID", use: self.update)
        protected.delete(":locationID", use: self.delete)
    }
    
    func index(req: Request) async throws -> [Location] {
        var query = Location.query(on: req.db)
        
        if let activeOnly = req.query[Bool.self, at: "active"], activeOnly {
            try await query.filter(\.$isActive == true)
        }
        
        return try await query.all()
    }
    
    func show(req: Request) async throws -> Location {
        guard let location = try await Location.find(req.parameters.get("locationID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return location
    }
    
    func create(req: Request) async throws -> Location {
        try await req.auth.require(User.self)
        
        let locationDTO = try req.content.decode(LocationDTO.self)
        
        guard let name = locationDTO.name,
              let address = locationDTO.address,
              let city = locationDTO.city,
              let country = locationDTO.country else {
            throw Abort(.badRequest, reason: "Name, address, city, and country are required")
        }
        
        let location = Location(
            name: name,
            address: address,
            city: city,
            state: locationDTO.state,
            zipCode: locationDTO.zipCode,
            country: country,
            latitude: locationDTO.latitude,
            longitude: locationDTO.longitude,
            phone: locationDTO.phone,
            isActive: locationDTO.isActive ?? true
        )
        
        try await location.save(on: req.db)
        return location
    }
    
    func update(req: Request) async throws -> Location {
        try await req.auth.require(User.self)
        
        guard let location = try await Location.find(req.parameters.get("locationID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let locationDTO = try req.content.decode(LocationDTO.self)
        
        if let name = locationDTO.name {
            location.name = name
        }
        if let address = locationDTO.address {
            location.address = address
        }
        if let city = locationDTO.city {
            location.city = city
        }
        if let state = locationDTO.state {
            location.state = state
        }
        if let zipCode = locationDTO.zipCode {
            location.zipCode = zipCode
        }
        if let country = locationDTO.country {
            location.country = country
        }
        if let latitude = locationDTO.latitude {
            location.latitude = latitude
        }
        if let longitude = locationDTO.longitude {
            location.longitude = longitude
        }
        if let phone = locationDTO.phone {
            location.phone = phone
        }
        if let isActive = locationDTO.isActive {
            location.isActive = isActive
        }
        
        try await location.save(on: req.db)
        return location
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        try await req.auth.require(User.self)
        
        guard let location = try await Location.find(req.parameters.get("locationID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await location.delete(on: req.db)
        return .noContent
    }
}

