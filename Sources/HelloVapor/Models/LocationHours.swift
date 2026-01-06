import Fluent
import Vapor
import Foundation

enum DayOfWeek: String, Codable, Content {
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday
}

final class LocationHours: Model, Content, @unchecked Sendable {
    static let schema = "location_hours"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "location_id")
    var location: Location
    
    @Field(key: "day_of_week")
    var dayOfWeek: DayOfWeek
    
    @Field(key: "open_time")
    var openTime: String
    
    @Field(key: "close_time")
    var closeTime: String
    
    @Field(key: "is_closed")
    var isClosed: Bool
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, locationID: UUID, dayOfWeek: DayOfWeek, openTime: String, closeTime: String, isClosed: Bool = false) {
        self.id = id
        self.$location.id = locationID
        self.dayOfWeek = dayOfWeek
        self.openTime = openTime
        self.closeTime = closeTime
        self.isClosed = isClosed
    }
}

