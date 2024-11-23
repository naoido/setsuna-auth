import Vapor
import Fluent
import JWT

struct Response: Content{
    let token: String
}

struct UserID: Content{
    let user_id: String
}

struct Ready: Content{
    let is_ready: Bool
}

struct RoomID: Content{
    let room_id: String
}

struct MessageResponse: Content{
    let message: String
}

struct ReadyUser: Content{
    let user_id: String!
    let room_id: String!
}
    

struct TestPayload: JWTPayload{
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
    }
    
    var subject: SubjectClaim
    
    var expiration: ExpirationClaim
    
    func verify(using algorithm: some JWTAlgorithm) async throws{
        try self.expiration.verifyNotExpired()
    }
}

func routes(_ app: Application) throws {
    app.get("check") { req async throws -> HTTPStatus in
        do {
            let payload = try await req.jwt.verify(as: TestPayload.self)
            return .ok
        } catch {
            req.logger.error("JWT認証失敗: \(error.localizedDescription)")
            throw Abort(.unauthorized, reason: "JWTの認証に失敗しました")
        }
    }
    
    app.get("user") { req async throws -> UserID in
        print(req)
        let payload = try await req.jwt.verify(as: TestPayload.self)
        return UserID(user_id: payload.subject.value)
    }
    
    app.post("room") { req async throws ->  RoomID in
        let room = Room(status: false)
        try await room.save(on: req.db)
        
        print(room)
        
        return RoomID(room_id: room.id!.uuidString)
    }
    
    
    app.post("ready") { req async throws -> String in
        let payload = try await req.jwt.verify(as: TestPayload.self)

        let user_id = payload.subject.value
        
        guard let uuid = UUID(uuidString: user_id),
        let user = try await RoomUser.query(on: req.db).filter(\.$id == uuid).first() else {
            throw Abort(.unauthorized, reason: "")
        }
        print(user)
        return "hello"
    }
    
//    app.get("ready") { req async throws -> Ready in
//        let request = try req.content.decode(ReadyUser.self)
//        guard let is_ready = try await RoomUser.query(on: req.db).filter(\.$roomID.id = request.user_id).first() else {
//            throw Abort(.notFound, reason: "ユーザーが見つかりません")
//    
//        }
//        
//        return Ready(is_ready: true)
//    }
    
    app.post("login") { req async throws -> Response in
        let request = try req.content.decode(LoginUser.self)
        guard let user = try await User.query(on: req.db).filter(\.$email == request.email).first() else {
            throw Abort(.unauthorized, reason: "ユーザ情報が違います")
        }
        
        guard try Bcrypt.verify(request.password, created: user.password) else {
            throw Abort(.unauthorized, reason: "ユーザー情報が違います")
        }
        
        let payload = TestPayload(
            subject: .init(value: user.id!.uuidString),
            expiration: .init(value: .distantFuture)
        )
        
        return try await Response(token: req.jwt.sign(payload))
    }
    
    
    app.post("register") { req async throws -> Response in
        let request = try req.content.decode(User.self)
        
        if try await User.query(on: req.db)
            .filter(\.$name == request.name)
            .first() != nil {
            throw Abort(.conflict, reason: "すでに登録されてるユーザー名です")
        }
        
        if try await User.query(on: req.db)
            .filter(\.$email == request.email)
            .first() != nil {
            throw Abort(.conflict, reason: "すでに登録されてるメールアドレスです")
        }
        
        let hashPassword = try Bcrypt.hash(request.password)
        
        let user = User(email: request.email, name: request.name, password: hashPassword)
        try await user.save(on: req.db)
        
        let payload = TestPayload(
            subject: .init(value: user.id!.uuidString),
            expiration: .init(value: .distantFuture)
        )
        return try await Response(token: req.jwt.sign(payload))
    }
        
        
}




