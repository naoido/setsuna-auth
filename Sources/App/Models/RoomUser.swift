import Vapor
import Fluent

final class RoomUser: Model, Content, @unchecked Sendable {
    static let schema = "room_users"

    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "room_id")
    var roomID: Room.IDValue
    
    @Field(key: "user_id")
    var userId: User.IDValue
    
    @Field(key: "is_ready")
    var isReady: Bool
    
    @Field(key: "score")
    var score: Int?
    
    init() { }


    init(id: UUID? = nil, userID: UUID, roomID: UUID, isReady: Bool, score: Int?) {
        self.id = id
        self.roomID = roomID
        self.userId = userID
        self.isReady = isReady
        self.score = score
    }
}
