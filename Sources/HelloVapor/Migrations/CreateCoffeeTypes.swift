import Fluent

struct CreateCoffeeTypes: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("coffee_types")
            .id()
            .field("name", .string, .required)
            .field("description", .string)
            .field("price", .double, .required)
            .field("image_url", .string)
            .field("is_available", .bool, .required, .sql(.default(true)))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("coffee_types").delete()
    }
}

