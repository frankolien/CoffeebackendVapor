import Fluent
import Vapor
import JWT

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("register", use: self.register)
        auth.post("login", use: self.login)
        
        let protected = auth.grouped(JWTAuthenticator())
        protected.get("me", use: self.me)
    }
    
    func register(req: Request) async throws -> AuthResponseDTO {
        try UserRegisterDTO.validate(content: req)
        let registerDTO = try req.content.decode(UserRegisterDTO.self)
        
        guard registerDTO.password.count >= 8 else {
            throw Abort(.badRequest, reason: "Password must be at least 8 characters")
        }
        
        let existingUser = try await User.query(on: req.db)
            .filter(\.$email == registerDTO.email)
            .first()
        
        if existingUser != nil {
            throw Abort(.conflict, reason: "User with this email already exists")
        }
        
        let passwordHash = try Bcrypt.hash(registerDTO.password)
        let user = User(
            email: registerDTO.email,
            passwordHash: passwordHash,
            fullName: registerDTO.fullName,
            phone: registerDTO.phone
        )
        
        try await user.save(on: req.db)
        
        let token = try generateToken(for: user, on: req)
        return AuthResponseDTO(
            user: UserResponseDTO(from: user),
            token: token
        )
    }
    
    func login(req: Request) async throws -> AuthResponseDTO {
        let loginDTO = try req.content.decode(UserLoginDTO.self)
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == loginDTO.email)
            .first() else {
            throw Abort(.unauthorized, reason: "Invalid email or password")
        }
        
        guard try user.verify(password: loginDTO.password) else {
            throw Abort(.unauthorized, reason: "Invalid email or password")
        }
        
        let token = try generateToken(for: user, on: req)
        return AuthResponseDTO(
            user: UserResponseDTO(from: user),
            token: token
        )
    }
    
    func me(req: Request) async throws -> UserResponseDTO {
        let user = try req.auth.require(User.self)
        return UserResponseDTO(from: user)
    }
    
    private func generateToken(for user: User, on req: Request) throws -> String {
        let expiration = Date().addingTimeInterval(3600 * 24 * 7)
        let payload = UserPayload(
            subject: .init(value: user.id!.uuidString),
            expiration: .init(value: expiration),
            userId: user.id!,
            isAdmin: user.isAdmin
        )
        
        return try req.jwt.sign(payload)
    }
}

struct UserPayload: JWTPayload {
    var subject: SubjectClaim
    var expiration: ExpirationClaim
    var userId: UUID
    var isAdmin: Bool
    
    func verify(using signer: JWTSigner) throws {
        try expiration.verifyNotExpired()
    }
}

