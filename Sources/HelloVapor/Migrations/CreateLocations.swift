import Fluent

struct CreateLocations: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("locations")
            .id()
            .field("name", .string, .required)
            .field("address", .string, .required)
            .field("city", .string, .required)
            .field("state", .string)
            .field("zip_code", .string)
            .field("country", .string, .required)
            .field("latitude", .double)
            .field("longitude", .double)
            .field("phone", .string)
            .field("is_active", .bool, .required, .sql(.default(true)))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("locations").delete()
    }
}

