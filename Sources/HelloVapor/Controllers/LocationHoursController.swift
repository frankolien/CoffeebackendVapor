import Fluent
import Vapor
import Foundation

struct LocationHoursController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let hours = routes.grouped("location-hours")
        
        hours.get("location", ":locationID", use: self.getByLocation)
        hours.get("location", ":locationID", "availability", use: self.getAvailability)
        
        let protected = hours.grouped(JWTAuthenticator())
        protected.post("location", ":locationID", use: self.create)
        protected.put(":hoursID", use: self.update)
        protected.delete(":hoursID", use: self.delete)
    }
    
    func getByLocation(req: Request) async throws -> [LocationHours] {
        guard let locationID = req.parameters.get("locationID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        return try await LocationHours.query(on: req.db)
            .filter(\.$location.$id == locationID)
            .sort(\.$dayOfWeek, .ascending)
            .all()
    }
    
    func getAvailability(req: Request) async throws -> LocationAvailabilityDTO {
        guard let locationID = req.parameters.get("locationID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        guard let location = try await Location.find(locationID, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let dayMapping: [Int: DayOfWeek] = [
            1: .sunday, 2: .monday, 3: .tuesday, 4: .wednesday,
            5: .thursday, 6: .friday, 7: .saturday
        ]
        
        guard let todayDay = dayMapping[weekday] else {
            throw Abort(.internalServerError)
        }
        
        let todayHours = try await LocationHours.query(on: req.db)
            .filter(\.$location.$id == locationID)
            .filter(\.$dayOfWeek == todayDay)
            .first()
        
        let isOpen = todayHours != nil && !todayHours!.isClosed
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let currentTime = formatter.string(from: today)
        
        var isCurrentlyOpen = false
        if let hours = todayHours, !hours.isClosed {
            if let openTime = parseTime(hours.openTime),
               let closeTime = parseTime(hours.closeTime),
               let current = parseTime(currentTime) {
                isCurrentlyOpen = current >= openTime && current < closeTime
            }
        }
        
        return LocationAvailabilityDTO(
            locationID: locationID,
            locationName: location.name,
            isCurrentlyOpen: isOpen && isCurrentlyOpen,
            currentHours: todayHours,
            nextOpenTime: nil
        )
    }
    
    func create(req: Request) async throws -> LocationHours {
        try await req.auth.require(User.self)
        
        guard let locationID = req.parameters.get("locationID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        let hoursDTO = try req.content.decode(LocationHoursDTO.self)
        
        guard let dayOfWeek = hoursDTO.dayOfWeek,
              let openTime = hoursDTO.openTime,
              let closeTime = hoursDTO.closeTime else {
            throw Abort(.badRequest, reason: "dayOfWeek, openTime, and closeTime are required")
        }
        
        let hours = hoursDTO.toModel(locationID: locationID)
        try await hours.save(on: req.db)
        
        return hours
    }
    
    func update(req: Request) async throws -> LocationHours {
        try await req.auth.require(User.self)
        
        guard let hours = try await LocationHours.find(req.parameters.get("hoursID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let hoursDTO = try req.content.decode(LocationHoursDTO.self)
        
        if let dayOfWeek = hoursDTO.dayOfWeek {
            hours.dayOfWeek = dayOfWeek
        }
        if let openTime = hoursDTO.openTime {
            hours.openTime = openTime
        }
        if let closeTime = hoursDTO.closeTime {
            hours.closeTime = closeTime
        }
        if let isClosed = hoursDTO.isClosed {
            hours.isClosed = isClosed
        }
        
        try await hours.save(on: req.db)
        return hours
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        try await req.auth.require(User.self)
        
        guard let hours = try await LocationHours.find(req.parameters.get("hoursID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await hours.delete(on: req.db)
        return .noContent
    }
    
    private func parseTime(_ timeString: String) -> Int? {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return nil
        }
        return hour * 60 + minute
    }
}

