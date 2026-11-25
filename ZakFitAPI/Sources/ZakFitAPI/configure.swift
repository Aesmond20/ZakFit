import NIOSSL
import Fluent
import FluentMySQLDriver
import JWT
import Vapor

/// Configure l'application
func configure(_ app: Application) async throws {

    // MARK: - CORS
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .PATCH, .DELETE, .OPTIONS],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    )
    app.middleware.use(CORSMiddleware(configuration: corsConfiguration), at: .beginning)
    
    // MARK: - Base de données (MySQL de XAMPP)
    app.databases.use(.mysql(
        hostname: Environment.get("DATABASE_HOST") ?? "127.0.0.1",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 3306,
        username: Environment.get("DATABASE_USERNAME") ?? "root",
        password: Environment.get("DATABASE_PASSWORD") ?? "",
        database: Environment.get("DATABASE_NAME") ?? "zakfit",
        tlsConfiguration: nil
    ), as: .mysql)
    
    // MARK: - Mots de passe
    app.passwords.use(.bcrypt(cost: 12))
    
    // MARK: - JWT
    // Le secret vient du .env, jamais du code.
    guard let jwtSecret = Environment.get("JWT_SECRET") else {
        fatalError("JWT_SECRET manquant dans le fichier .env")
    }
    await app.jwt.keys.add(hmac: HMACKey(from: jwtSecret), digestAlgorithm: .sha256)
    
    // MARK: - Routes
    try routes(app)
}
