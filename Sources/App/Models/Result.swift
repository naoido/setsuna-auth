import Vapor
import Fluent

final class Result: Model, Content, @unchecked Sendable {
    static let schema = "results"

    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "room_id")
    var roomID: Room
    
    @Field(key: "score")
    var score: Int
    
    init() { }


    init(id: UUID? = nil, userID: UUID, roomID: UUID, score: Int) {
        self.id = id
        self.$user.id = userID
        self.$roomID.id = roomID
        self.score = score
    }
}


