import Vapor
import Fluent

final class Point: Model, Content, @unchecked Sendable {
    static let schema = "points"

    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Field(key: "point")
    var point: Int
    
    init() { }


    init(id: UUID? = nil, userID: UUID, point: Int) {
        self.id = id
        self.$user.id = userID
        self.point = point
    }
}


