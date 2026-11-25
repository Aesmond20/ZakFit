//
//  AuthControllerTests.swift
//  ZakFitAPI
//
//  Created by Aesmond on 25/11/2026.
//

@testable import ZakFitAPI
import Fluent
import Testing
import VaporTesting

/// Tests de POST /auth/register.
@Suite("Auth — inscription", .serialized)
struct AuthControllerTests {
    
    /// Démarre l'application de test, lance le test, puis l'arrête.
    private func withApp(_ test: (Application) async throws -> ()) async throws {
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
    
    /// Corps d'inscription valide.
    private func makeRegisterBody(
        email: String = "test.\(UUID().uuidString.prefix(8))@email.fr",
        firstName: String = "Camille",
        password: String = "ZakFit2026!",
        confirmPassword: String = "ZakFit2026!"
    ) -> RegisterUserDTO {
        RegisterUserDTO(
            firstName: firstName,
            lastName: "Durand",
            email: email,
            password: password,
            confirmPassword: confirmPassword
        )
    }
    
    /// Supprime le compte créé par un test.
    private func deleteUser(email: String, on database: any Database) async throws {
        try await User.query(on: database)
            .filter(\.$email == email.lowercased())
            .delete()
    }
    
    @Test("201 : crée le compte et renvoie un token, sans mot de passe")
    func registerCreatesUser() async throws {
        try await withApp { app in
            let body = makeRegisterBody()
            
            try await app.testing().test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode(body)
            }, afterResponse: { res async throws in
                #expect(res.status == .created)
                let response = try res.content.decode(AuthResponseDTO.self)
                #expect(!response.token.isEmpty)
                #expect(response.user.email == body.email.lowercased())
                #expect(!res.body.string.contains("passwordHash"))
            })
            
            // Le compte existe bien.
            let savedUser = try await User.query(on: app.db)
                .filter(\.$email == body.email.lowercased())
                .first()
            #expect(savedUser != nil)
            
            try await deleteUser(email: body.email, on: app.db)
        }
    }
    
    @Test("409 : email déjà utilisé, même avec une casse différente")
    func registerRejectsSameEmail() async throws {
        try await withApp { app in
            let identifier = UUID().uuidString.prefix(8).lowercased()
            let body = makeRegisterBody(email: "test.\(identifier)@email.fr")
            try await app.testing().test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode(body)
            })

            // Même adresse, partie avant le @ en majuscules : doit être refusée.
            let sameEmailBody = makeRegisterBody(email: "TEST.\(identifier.uppercased())@email.fr")
            try await app.testing().test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode(sameEmailBody)
            }, afterResponse: { res async in
                #expect(res.status == .conflict)
            })

            try await deleteUser(email: body.email, on: app.db)
        }
    }
    
    @Test("400 : email invalide")
    func registerRejectsInvalidEmail() async throws {
        try await withApp { app in
            let body = makeRegisterBody(email: "pas-un-email")
            try await app.testing().test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode(body)
            }, afterResponse: { res async in
                #expect(res.status == .badRequest)
            })
        }
    }
    
    @Test("400 : mot de passe de moins de 8 caractères")
    func registerRejectsShortPassword() async throws {
        try await withApp { app in
            let body = makeRegisterBody(password: "court", confirmPassword: "court")
            try await app.testing().test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode(body)
            }, afterResponse: { res async in
                #expect(res.status == .badRequest)
            })
        }
    }
    
    @Test("400 : la confirmation ne correspond pas au mot de passe")
    func registerRejectsPasswordMismatch() async throws {
        try await withApp { app in
            let body = makeRegisterBody(confirmPassword: "ZakFit2027!")
            try await app.testing().test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode(body)
            }, afterResponse: { res async in
                #expect(res.status == .badRequest)
            })
        }
    }
    
    @Test("400 : prénom vide")
    func registerRejectsEmptyFirstName() async throws {
        try await withApp { app in
            let body = makeRegisterBody(firstName: "")
            try await app.testing().test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode(body)
            }, afterResponse: { res async in
                #expect(res.status == .badRequest)
            })
        }
    }
}
