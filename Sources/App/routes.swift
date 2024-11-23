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

struct RoomsID: Content{
    let room_id: String
}

struct RID : Content{
    let room_id: String
}

struct RoomID: Content{
    let room_id: String
}
    
struct MessageResponse: Content{
    let message: String
}

struct ResultResponse: Content{
    let score: Int
    let room_id: String
}

struct ReadyUser: Content{
    let user_id: String!
    let room_id: String!
}

struct Power: Content{
    let room_id: String
    let power: Int
}

struct Matching: Content {
    let is_leave: Bool
}

struct MatchStatus: Content {
    let user_count: Int
    let is_matched: Bool
    let room_id: String?
}

struct ResultMsg: Content {
    let result: String?
}

var pool: [String:Bool] = [:]
var ready: [String:Bool]? = nil
var room_id: String? = nil


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
    
    app.post("result") { req async throws -> ResultMsg in
            let payload = try await req.jwt.verify(as: TestPayload.self)
            let user_id = payload.subject.value
            let result = try req.content.decode(ResultResponse.self)
            let room_id = result.room_id
            
            if (UUID(room_id) == nil) {
                throw Abort(.badRequest, reason: "room_id is not UUID")
            }
            
            let room = UUID(uuidString: room_id)!
            let user = UUID(uuidString: user_id)!
            
            let old_user = try await RoomUser.query(on: req.db)
                .filter(\.$roomID == room)
                .filter(\.$userId == user).first()
            
            old_user?.score = result.score
            try await old_user?.save(on: req.db)
            
            let nil_result_user = RoomUser.query(on: req.db).filter(\.$roomID == room).filter(\.$score == nil)
            let results: RoomUser? = try await nil_result_user.first()
            
            // 全員の処理が完了していない場合
            if (results != nil) {
                return ResultMsg(result: "")
            }
           // Fetch all users in the room and sort by score descending
           let all_users = try await RoomUser.query(on: req.db)
               .filter(\.$roomID == room)
               .sort(\.$score, .ascending)
               .all()
            if all_users.first!.score == result.score {
               return ResultMsg(result: "win")
           } else {
               return ResultMsg(result: "lose")
           }
    }
    
    app.post("matching") { req async throws -> MatchStatus in
        let payload = try await req.jwt.verify(as: TestPayload.self)
        let user_id: String = payload.subject.value
        
        if (UUID(user_id) == nil) {
            throw Abort(.badRequest, reason: "user_is is not UUID")
        }
        
        if (try req.content.decode(Matching.self).is_leave) {
            pool.removeValue(forKey: user_id)
            return MatchStatus.init(user_count: pool.count, is_matched: false, room_id: nil)
        }
        
        // マッチングプールにユーザーを追加
        if (pool[user_id] == nil) {
            pool.updateValue(false, forKey: user_id)
        }
        
        if (1 < pool.count) {
            if (room_id == nil) {
                let new_room = Room(status: true)
                try await new_room.save(on: req.db)
                
                room_id = new_room.id?.uuidString
                
                // ルームユーザーを追加
                for (key, value) in pool {
                    let new_room_user = RoomUser.init(userID: UUID(key)!, roomID: new_room.id!, isReady: false, score: nil)
                    try await new_room_user.create(on: req.db)
                }
            }
            
            pool.updateValue(true, forKey: user_id)
        }
        
        let is_matched = pool.values.allSatisfy { $0 }
        let match_status = MatchStatus.init(user_count: pool.count, is_matched: is_matched, room_id: room_id)
        
        // マッチングプールを初期化
        if (is_matched && ready == nil) {
            ready = [:]
            for (key, _) in pool {
                ready!.updateValue(false, forKey: key)
            }
            
            ready!.updateValue(true, forKey: user_id)
        } else if (ready != nil) {
            ready!.updateValue(true, forKey: user_id)
            let is_all_user_ready = ready!.values.allSatisfy { $0 }
            // 全員マッチ完了を取得したら初期化
            if (is_all_user_ready) {
                pool.removeAll()
                ready = nil
                room_id = nil
            }
        }
        
        return match_status
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
