import Fluent
import Vapor

struct CreateTitleName: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("title_names")
            .id()
            .field("title_id", .uuid, .references("titles", "id"))
            .field("name", .string)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("title_names").delete()
    }
}


