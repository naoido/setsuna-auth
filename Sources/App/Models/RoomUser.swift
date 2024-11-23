import Vapor
import Fluent

final class RoomUser: Model, Content, @unchecked Sendable {
    static let schema = "room_users"

    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "room_id")
    var roomID: Room
    
    @Parent(key: "user_id")
    var user: User
    
    @Field(key: "is_ready")
    var isReady: Bool
    
    
    init() { }


    init(id: UUID? = nil, userID: UUID, roomID: UUID, isReady: Bool) {
        self.id = id
        self.$roomID.id = roomID
        self.$user.id = userID
        self.isReady = isReady
    }
}
