import JWT
import Vapor

func routes(_ app: Application) throws {

    // Routes publiques
    try app.register(collection: AuthController())

    // Routes protégées
    let protected = app.grouped(
        UserPayload.authenticator(),
        UserPayload.guardMiddleware(throwing: Abort(.unauthorized, reason: "Authentication required"))
    )
    try protected.register(collection: UserController())
}
