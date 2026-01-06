import Fluent

struct AddOrderCustomization: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("orders")
            .field("size", .string)
            .field("milk_type", .string)
            .field("extras", .string)
            .update()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("orders")
            .deleteField("size")
            .deleteField("milk_type")
            .deleteField("extras")
            .update()
    }
}

