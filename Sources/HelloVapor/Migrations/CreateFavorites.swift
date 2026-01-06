import Fluent

struct CreateFavorites: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("favorites")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("coffee_type_id", .uuid, .required, .references("coffee_types", "id", onDelete: .cascade))
            .field("created_at", .datetime)
            .unique(on: "user_id", "coffee_type_id")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("favorites").delete()
    }
}

