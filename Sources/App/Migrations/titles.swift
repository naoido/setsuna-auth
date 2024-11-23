import Fluent
import Vapor

struct CreateTitle: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("titles")
            .id()
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("titles").delete()
    }
}


