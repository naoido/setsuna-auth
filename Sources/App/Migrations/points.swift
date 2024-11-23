import Vapor
import Fluent

struct CreatePoint: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("points")
            .id()
            .field("user_id", .uuid, .references("users", "id"))
            .field("points", .int)
            .create()
    }

    // 必要に応じて、prepare メソッドで行った変更を元に戻します
    func revert(on database: Database) async throws {
        try await database.schema("points").delete()
    }
}
