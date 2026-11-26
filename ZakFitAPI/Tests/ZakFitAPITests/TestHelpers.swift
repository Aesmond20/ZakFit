//
//  TestHelpers.swift
//  ZakFitAPI
//
//  Created by Aesmond on 26/11/2026.
//

@testable import ZakFitAPI
import Testing
import Fluent
import VaporTesting

/// Démarre l'application de test, lance le test, puis l'arrête.
func withTestApp(_ test: (Application) async throws -> ()) async throws {
    setenv("DATABASE_NAME", "zakfit_test", 1)
    setenv("JWT_SECRET", "zakfit-test-secret-not-for-production", 1)

    let app = try await Application.make(.testing)
    do {
        try await configure(app)
        try await test(app)
    } catch {
        try await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}

/// Connexion avec un compte fictif et renvoie son token.
func loginToken(email: String, app: Application) async throws -> String {
    var token = ""
    try await app.testing().test(.POST, "auth/login", beforeRequest: { req in
        try req.content.encode(LoginDTO(email: email, password: "ZakFit2026!"))
    }, afterResponse: { res async throws in
        #expect(res.status == .ok)
        token = try res.content.decode(AuthResponseDTO.self).token
    })
    return token
}

/// Crée un compte de test et renvoie son token et son email.
func registerTestUser(app: Application) async throws -> (token: String, email: String) {
    let email = "test.\(UUID().uuidString.prefix(8).lowercased())@email.fr"
    var token = ""
    try await app.testing().test(.POST, "auth/register", beforeRequest: { req in
        try req.content.encode(RegisterUserDTO(firstName: "Camille", lastName: "Durand", email: email,
                                               password: "ZakFit2026!", confirmPassword: "ZakFit2026!"))
    }, afterResponse: { res async throws in
        #expect(res.status == .created)
        token = try res.content.decode(AuthResponseDTO.self).token
    })
    return (token, email)
}

/// Supprime un compte de test (ses préférences partent avec, grâce à ON DELETE CASCADE).
func deleteTestUser(email: String, on database: any Database) async throws {
    try await User.query(on: database)
        .filter(\.$email == email.lowercased())
        .delete()
}
