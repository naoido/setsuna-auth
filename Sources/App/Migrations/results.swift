import Fluent
import Vapor

struct CreateResult: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("results")
            .id()
            .field("room_id", .uuid, .references("rooms", "id"))
            .field("user_id", .uuid, .references("users", "id"))
            .field("score", .int)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("results").delete()
    }
}

