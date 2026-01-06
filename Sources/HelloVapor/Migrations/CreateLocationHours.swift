import Fluent

struct CreateLocationHours: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("location_hours")
            .id()
            .field("location_id", .uuid, .required, .references("locations", "id", onDelete: .cascade))
            .field("day_of_week", .string, .required)
            .field("open_time", .string, .required)
            .field("close_time", .string, .required)
            .field("is_closed", .bool, .required, .sql(.default(false)))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "location_id", "day_of_week")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("location_hours").delete()
    }
}

