import Vapor
import Fluent
import JWT

struct Response: Content{
    let token: String
}

struct UserID: Content{
    let userID: String
}

struct MessageResponse: Content{
    let message: String
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
        let payload = try await req.jwt.verify(as: TestPayload.self)
        return UserID(userID: payload.subject.value)
    }
    
    
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




