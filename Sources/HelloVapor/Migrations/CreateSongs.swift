import Fluent

struct CreateSongs: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("songs")
            .id()
            .field("title", .string, .required)
            .field("artist", .string, .required)
            .field("duration", .int, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("songs").delete()
    }
}