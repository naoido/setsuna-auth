import Vapor
import FluentMySQLDriver
import Fluent
// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // register routes
    await app.jwt.keys.add(hmac: "hack2", digestAlgorithm: .sha256)
    
    var tls = TLSConfiguration.makeClientConfiguration()
    tls.certificateVerification = .none

    app.databases.use(.mysql(
        hostname: "127.0.0.1",
        username: "root",
        password: "password",
        database: "mydb",
        tlsConfiguration: tls
    ), as: .mysql)
    app.migrations.add(CreateUser())
    app.migrations.add(CreateTitle())
    app.migrations.add(CreateTitleName())
    app.migrations.add(CreateRoom())
    app.migrations.add(CreateRoomUser())
    app.migrations.add(CreatePoint())
    app.migrations.add(CreateResult())
    try routes(app)
}
