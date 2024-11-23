import Vapor
import Fluent

struct CreateRoomUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("room_users")
            .id()
            .field("room_id", .uuid, .references("rooms", "id"), .required)
            .field("user_id", .uuid, .references("users", "id"), .required)
            .field("is_ready", .bool, .sql(.default(0)), .required)
            .field("result", .int)
            .create()
    }

    // 必要に応じて、prepare メソッドで行った変更を元に戻します
    func revert(on database: Database) async throws {
        try await database.schema("room_users").delete()
    }
}
