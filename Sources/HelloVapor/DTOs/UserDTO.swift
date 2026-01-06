import Fluent
import Vapor
import Foundation

struct UserRegisterDTO: Content, Validatable {
    var email: String
    var password: String
    var fullName: String
    var phone: String?
    
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
        validations.add("fullName", as: String.self, is: !.empty)
    }
}

struct UserLoginDTO: Content {
    var email: String
    var password: String
}

struct UserResponseDTO: Content {
    var id: UUID?
    var email: String
    var fullName: String
    var phone: String?
    var isAdmin: Bool
    var createdAt: Date?
    
    init(from user: User) {
        self.id = user.id
        self.email = user.email
        self.fullName = user.fullName
        self.phone = user.phone
        self.isAdmin = user.isAdmin
        self.createdAt = user.createdAt
    }
}

struct AuthResponseDTO: Content {
    var user: UserResponseDTO
    var token: String
}

