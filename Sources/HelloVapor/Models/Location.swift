import Fluent
import Vapor
import Foundation

final class Location: Model, Content, @unchecked Sendable {
    static let schema = "locations"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "address")
    var address: String
    
    @Field(key: "city")
    var city: String
    
    @Field(key: "state")
    var state: String?
    
    @Field(key: "zip_code")
    var zipCode: String?
    
    @Field(key: "country")
    var country: String
    
    @Field(key: "latitude")
    var latitude: Double?
    
    @Field(key: "longitude")
    var longitude: Double?
    
    @Field(key: "phone")
    var phone: String?
    
    @Field(key: "is_active")
    var isActive: Bool
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Children(for: \.$location)
    var orders: [Order]
    
    @Children(for: \.$location)
    var reviews: [Review]
    
    @Children(for: \.$location)
    var hours: [LocationHours]
    
    init() { }
    
    init(id: UUID? = nil, name: String, address: String, city: String, state: String? = nil, zipCode: String? = nil, country: String, latitude: Double? = nil, longitude: Double? = nil, phone: String? = nil, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.address = address
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.phone = phone
        self.isActive = isActive
    }
}

