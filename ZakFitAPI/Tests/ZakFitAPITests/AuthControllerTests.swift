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
@Suite("Auth — inscription et connexion", .serialized)
struct AuthControllerTests {
    
    // MARK: - Inscription
    
    /// Inscription valide.
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
        try await withTestApp { app in
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
        try await withTestApp { app in
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
        try await withTestApp { app in
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
        try await withTestApp { app in
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
        try await withTestApp { app in
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
        try await withTestApp { app in
            let body = makeRegisterBody(firstName: "")
            try await app.testing().test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode(body)
            }, afterResponse: { res async in
                #expect(res.status == .badRequest)
            })
        }
    }

    // MARK: - Connexion

    /// Compte des données fictives
    private let demoEmail = "ambre@email.fr"
    private let demoPassword = "ZakFit2026!"

    @Test("200 : connexion réussie, renvoie un token et l'utilisateur")
    func loginReturnsToken() async throws {
        try await withTestApp { app in
            let body = LoginDTO(email: demoEmail, password: demoPassword)
            try await app.testing().test(.POST, "auth/login", beforeRequest: { req in
                try req.content.encode(body)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(AuthResponseDTO.self)
                #expect(!response.token.isEmpty)
                #expect(response.user.email == demoEmail)
            })
        }
    }

    @Test("401 : mauvais mot de passe")
    func loginRejectsWrongPassword() async throws {
        try await withTestApp { app in
            let body = LoginDTO(email: demoEmail, password: "mauvais-mdp")
            try await app.testing().test(.POST, "auth/login", beforeRequest: { req in
                try req.content.encode(body)
            }, afterResponse: { res async in
                #expect(res.status == .unauthorized)
                #expect(res.body.string.contains("Invalid email or password"))
            })
        }
    }

    @Test("401 : email inconnu, avec le même message que le mauvais mot de passe")
    func loginRejectsUnknownEmail() async throws {
        try await withTestApp { app in
            let body = LoginDTO(email: "inconnu@email.fr", password: demoPassword)
            try await app.testing().test(.POST, "auth/login", beforeRequest: { req in
                try req.content.encode(body)
            }, afterResponse: { res async in
                #expect(res.status == .unauthorized)
                #expect(res.body.string.contains("Invalid email or password"))
            })
        }
    }

    @Test("400 : email au mauvais format")
    func loginRejectsInvalidEmail() async throws {
        try await withTestApp { app in
            let body = LoginDTO(email: "pas-un-email", password: demoPassword)
            try await app.testing().test(.POST, "auth/login", beforeRequest: { req in
                try req.content.encode(body)
            }, afterResponse: { res async in
                #expect(res.status == .badRequest)
            })
        }
    }
}
