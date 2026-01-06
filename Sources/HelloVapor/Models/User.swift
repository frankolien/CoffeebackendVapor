import Fluent
import Vapor
import Foundation

final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Field(key: "full_name")
    var fullName: String
    
    @Field(key: "phone")
    var phone: String?
    
    @Field(key: "is_admin")
    var isAdmin: Bool
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Children(for: \.$user)
    var orders: [Order]
    
    @Children(for: \.$user)
    var reviews: [Review]
    
    @Children(for: \.$user)
    var favorites: [Favorite]
    
    init() { }
    
    init(id: UUID? = nil, email: String, passwordHash: String, fullName: String, phone: String? = nil, isAdmin: Bool = false) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.fullName = fullName
        self.phone = phone
        self.isAdmin = isAdmin
    }
}

extension User {
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

