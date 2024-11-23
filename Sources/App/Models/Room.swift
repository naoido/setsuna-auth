import Vapor
import Fluent

final class Room: Model, Content, @unchecked Sendable {
    static let schema = "rooms"

    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "status")
    var status: Bool

    
    init() { }


    init(id: UUID? = nil, status: Bool) {
        self.id = id
        self.status = status
    }
}

