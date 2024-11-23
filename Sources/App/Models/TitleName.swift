import Vapor
import Fluent

final class TitleName: Model, Content, @unchecked Sendable {
    static let schema = "title_names"

    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Parent(key: "title_id")
    var titleID: Title
    
    
    init() { }


    init(id: UUID? = nil, name: String, titleID: UUID) {
        self.id = id
        self.$titleID.id = titleID
        self.name = name
    }
}
