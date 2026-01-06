import Fluent

struct CreateOrders: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("orders")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("coffee_type_id", .uuid, .required, .references("coffee_types", "id", onDelete: .restrict))
            .field("location_id", .uuid, .required, .references("locations", "id", onDelete: .restrict))
            .field("quantity", .int, .required)
            .field("total_price", .double, .required)
            .field("status", .string, .required)
            .field("special_instructions", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("orders").delete()
    }
}

