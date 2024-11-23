import Vapor
import Fluent

final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password")
    var password: String

    init() { }


    init(id: UUID? = nil, email: String, name: String, password: String) {
        self.id = id
        self.email = email
        self.name = name
        self.password = password
    }
}

struct LoginUser: Content{
    var email: String
    var password: String
    
    init(email: String, password: String){
        self.email = email
        self.password = password
    }
}
