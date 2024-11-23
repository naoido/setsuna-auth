import Vapor
import Fluent

final class Title: Model, Content, @unchecked Sendable {
    static let schema = "titles"

    @ID(key: .id)
    var id: UUID?
    
    init() { }


    init(id: UUID? = nil) {
        self.id = id
    }
}

