import Fluent
import Vapor
import Foundation

struct LocationHoursDTO: Content {
    var id: UUID?
    var locationID: UUID?
    var dayOfWeek: DayOfWeek?
    var openTime: String?
    var closeTime: String?
    var isClosed: Bool?
    
    func toModel(locationID: UUID) -> LocationHours {
        let model = LocationHours()
        model.id = self.id
        model.$location.id = locationID
        if let dayOfWeek = self.dayOfWeek {
            model.dayOfWeek = dayOfWeek
        }
        if let openTime = self.openTime {
            model.openTime = openTime
        }
        if let closeTime = self.closeTime {
            model.closeTime = closeTime
        }
        if let isClosed = self.isClosed {
            model.isClosed = isClosed
        }
        return model
    }
}

struct LocationAvailabilityDTO: Content {
    var locationID: UUID
    var locationName: String
    var isCurrentlyOpen: Bool
    var currentHours: LocationHours?
    var nextOpenTime: String?
}

