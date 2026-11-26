//
//  UserControllerTests.swift
//  ZakFitAPI
//
//  Created by Aesmond on 26/11/2026.
//

@testable import ZakFitAPI
import Testing
import Fluent
import VaporTesting

/// Tests de GET /users/me.
@Suite("Profil", .serialized)
struct UserControllerTests {

    @Test("200 : renvoie le profil de l'utilisateur du token")
    func meReturnsProfile() async throws {
        try await withTestApp { app in
            let token = try await loginToken(email: "ambre@email.fr", app: app)

            try await app.testing().test(.GET, "users/me", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let user = try res.content.decode(UserDTO.self)
                #expect(user.email == "ambre@email.fr")
                #expect(user.heightCm == 169)
                #expect(user.dietaryPreferences.isEmpty)
                #expect(!res.body.string.contains("passwordHash"))
            })
        }
    }

    @Test("200 : renvoie les préférences alimentaires, triées")
    func meReturnsDietaryPreferences() async throws {
        try await withTestApp { app in
            let token = try await loginToken(email: "lea.martin@email.fr", app: app)

            try await app.testing().test(.GET, "users/me", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let user = try res.content.decode(UserDTO.self)
                #expect(user.dietaryPreferences == ["lactose_free", "vegetarian"])
            })
        }
    }

    @Test("401 : sans token")
    func meRejectsMissingToken() async throws {
        try await withTestApp { app in
            try await app.testing().test(.GET, "users/me", beforeRequest: { _ in
            }, afterResponse: { res async in
                #expect(res.status == .unauthorized)
                #expect(res.body.string.contains("Authentication required"))
            })
        }
    }

    @Test("401 : token invalide")
    func meRejectsInvalidToken() async throws {
        try await withTestApp { app in
            try await app.testing().test(.GET, "users/me", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: "pas-un-vrai-token")
            }, afterResponse: { res async in
                #expect(res.status == .unauthorized)
            })
        }
    }
    
    /// Tests de PUT /users/me
    private func makeUpdateBody(
        email: String,
        password: String? = nil,
        heightCm: Int? = 165,
        dietaryPreferences: [String] = ["vegetarian", "gluten_free"]
    ) -> UpdateUserDTO {
        UpdateUserDTO(
            firstName: "Camille", lastName: "Martin", email: email,
            password: password, confirmPassword: password,
            birthDate: nil, sex: .female, heightCm: heightCm, weightKg: 58.5,
            healthGoal: .maintain, dietaryPreferences: dietaryPreferences
        )
    }

    @Test("200 : met à jour le profil et les préférences, enregistrés en base")
    func updateChangesProfile() async throws {
        try await withTestApp { app in
            let (token, email) = try await registerTestUser(app: app)

            try await app.testing().test(.PUT, "users/me", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(makeUpdateBody(email: email))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let user = try res.content.decode(UserDTO.self)
                #expect(user.lastName == "Martin")
                #expect(user.heightCm == 165)
                #expect(user.dietaryPreferences == ["gluten_free", "vegetarian"])
            })

            // L'effet est réel : GET /users/me relit la même chose.
            try await app.testing().test(.GET, "users/me", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                let user = try res.content.decode(UserDTO.self)
                #expect(user.dietaryPreferences == ["gluten_free", "vegetarian"])
            })

            try await deleteTestUser(email: email, on: app.db)
        }
    }

    @Test("200 : le nouveau mot de passe permet de se connecter")
    func updateChangesPassword() async throws {
        try await withTestApp { app in
            let (token, email) = try await registerTestUser(app: app)

            try await app.testing().test(.PUT, "users/me", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(makeUpdateBody(email: email, password: "NouveauMdp2026"))
            }, afterResponse: { res async in
                #expect(res.status == .ok)
            })

            try await app.testing().test(.POST, "auth/login", beforeRequest: { req in
                try req.content.encode(LoginDTO(email: email, password: "NouveauMdp2026"))
            }, afterResponse: { res async in
                #expect(res.status == .ok)
            })

            try await deleteTestUser(email: email, on: app.db)
        }
    }

    @Test("409 : email déjà utilisé par un autre compte")
    func updateRejectsEmailOfOtherUser() async throws {
        try await withTestApp { app in
            let (token, email) = try await registerTestUser(app: app)

            try await app.testing().test(.PUT, "users/me", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(makeUpdateBody(email: "ambre@email.fr"))
            }, afterResponse: { res async in
                #expect(res.status == .conflict)
            })

            try await deleteTestUser(email: email, on: app.db)
        }
    }

    @Test("400 : taille hors des bornes")
    func updateRejectsInvalidHeight() async throws {
        try await withTestApp { app in
            let (token, email) = try await registerTestUser(app: app)

            try await app.testing().test(.PUT, "users/me", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(makeUpdateBody(email: email, heightCm: 40))
            }, afterResponse: { res async in
                #expect(res.status == .badRequest)
            })

            try await deleteTestUser(email: email, on: app.db)
        }
    }

    @Test("400 : préférence alimentaire inconnue")
    func updateRejectsUnknownPreference() async throws {
        try await withTestApp { app in
            let (token, email) = try await registerTestUser(app: app)

            try await app.testing().test(.PUT, "users/me", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(makeUpdateBody(email: email, dietaryPreferences: ["carnivore"]))
            }, afterResponse: { res async in
                #expect(res.status == .badRequest)
                #expect(res.body.string.contains("Unknown dietary preference"))
            })

            try await deleteTestUser(email: email, on: app.db)
        }
    }

    @Test("401 : sans token")
    func updateRejectsMissingToken() async throws {
        try await withTestApp { app in
            try await app.testing().test(.PUT, "users/me", beforeRequest: { req in
                try req.content.encode(makeUpdateBody(email: "camille.token@email.fr"))
            }, afterResponse: { res async in
                #expect(res.status == .unauthorized)
            })
        }
    }
}
