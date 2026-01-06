import Fluent

struct CreateReviews: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("reviews")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("coffee_type_id", .uuid, .references("coffee_types", "id", onDelete: .cascade))
            .field("location_id", .uuid, .references("locations", "id", onDelete: .cascade))
            .field("rating", .int, .required)
            .field("comment", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("reviews").delete()
    }
}

