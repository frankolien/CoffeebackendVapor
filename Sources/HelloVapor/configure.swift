import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import JWT

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)

    app.jwt.signers.use(.hs256(key: Environment.get("JWT_SECRET") ?? "your-secret-key-change-in-production"))
    
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    
    app.migrations.add(CreateUsers())
    app.migrations.add(CreateCoffeeTypes())
    app.migrations.add(CreateLocations())
    app.migrations.add(CreateOrders())
    app.migrations.add(CreateReviews())
    app.migrations.add(CreateFavorites())
    app.migrations.add(CreateLocationHours())
    app.migrations.add(AddOrderCustomization())
    
    try await app.autoMigrate()





    // register routes
    try routes(app)
}
