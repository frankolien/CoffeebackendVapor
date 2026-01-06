import Vapor
import JWT

struct JWTAuthenticator: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard let token = request.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized)
        }
        
        let payload = try request.jwt.verify(token, as: UserPayload.self)
        
        guard let user = try await User.find(payload.userId, on: request.db) else {
            throw Abort(.unauthorized)
        }
        
        request.auth.login(user)
        return try await next.respond(to: request)
    }
}

extension User: Authenticatable {}

