//
//  FoodControllerTests.swift
//  ZakFitAPI
//
//  Created by Aesmond on 27/11/2026.
//

@testable import ZakFitAPI
import Testing
import Fluent
import VaporTesting

/// Tests de GET /foods et POST /foods
@Suite("Aliments", .serialized)
struct FoodControllerTests {

    private func makeFoodBody(
        name: String = "Gratin maison",
        kcalPer100g: Double = 150,
        proteinPer100g: Double = 8,
        carbsPer100g: Double = 12,
        fatPer100g: Double = 7,
        portionWeightG: Double? = 250
    ) -> CreateFoodDTO {
        CreateFoodDTO(name: name, kcalPer100g: kcalPer100g, proteinPer100g: proteinPer100g,
                      carbsPer100g: carbsPer100g, fatPer100g: fatPer100g, portionWeightG: portionWeightG)
    }

    // MARK: - GET /foods

    @Test("200 : la recherche renvoie les aliments de base correspondants, triés par nom")
    func searchReturnsBaseFoodsSorted() async throws {
        try await withTestApp { app in
            let token = try await loginToken(email: "hugo.bernard@email.fr", app: app)

            try await app.testing().test(.GET, "foods?search=riz", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let foods = try res.content.decode([FoodDTO].self)
                #expect(foods.map(\.name) == ["Galette de riz soufflé", "Riz au lait", "Riz basmati cuit", "Riz complet cuit"])
                #expect(foods.allSatisfy { !$0.isCustom })
            })
        }
    }

    @Test("200 : la recherche ignore les accents et inclut les aliments perso de l'utilisateur")
    func searchIncludesOwnCustomFoods() async throws {
        try await withTestApp { app in
            let token = try await loginToken(email: "ambre@email.fr", app: app)

            try await app.testing().test(.GET, "foods?search=gateau", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let foods = try res.content.decode([FoodDTO].self)
                #expect(foods.count == 1)
                #expect(foods.first?.name == "Gâteau de mamie")
                #expect(foods.first?.isCustom == true)
            })
        }
    }

    @Test("200 : les aliments perso des autres utilisateurs ne sont pas visibles")
    func searchHidesOtherUsersFoods() async throws {
        try await withTestApp { app in
            let token = try await loginToken(email: "hugo.bernard@email.fr", app: app)

            try await app.testing().test(.GET, "foods?search=gateau", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let foods = try res.content.decode([FoodDTO].self)
                #expect(foods.isEmpty)
            })
        }
    }

    @Test("401 : sans token")
    func searchRejectsMissingToken() async throws {
        try await withTestApp { app in
            try await app.testing().test(.GET, "foods", beforeRequest: { _ in
            }, afterResponse: { res async in
                #expect(res.status == .unauthorized)
            })
        }
    }

    // MARK: - POST /foods

    @Test("201 : crée un aliment perso, visible ensuite dans la recherche")
    func createReturnsCustomFood() async throws {
        try await withTestApp { app in
            let (token, email) = try await registerTestUser(app: app)

            try await app.testing().test(.POST, "foods", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(makeFoodBody())
            }, afterResponse: { res async throws in
                #expect(res.status == .created)
                let food = try res.content.decode(FoodDTO.self)
                #expect(food.name == "Gratin maison")
                #expect(food.portionWeightG == 250)
                #expect(food.isCustom)
            })

            try await app.testing().test(.GET, "foods?search=gratin", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                let foods = try res.content.decode([FoodDTO].self)
                #expect(foods.map(\.name) == ["Gratin maison"])
            })

            try await deleteTestUser(email: email, on: app.db)
        }
    }

    @Test("400 : plus de 100 g de macros pour 100 g")
    func createRejectsTooManyMacros() async throws {
        try await withTestApp { app in
            let (token, email) = try await registerTestUser(app: app)

            try await app.testing().test(.POST, "foods", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(makeFoodBody(proteinPer100g: 50, carbsPer100g: 40, fatPer100g: 20))
            }, afterResponse: { res async in
                #expect(res.status == .badRequest)
                #expect(res.body.string.contains("cannot exceed 100 g"))
            })

            try await deleteTestUser(email: email, on: app.db)
        }
    }

    @Test("400 : calories hors bornes et nom vide")
    func createRejectsInvalidValues() async throws {
        try await withTestApp { app in
            let (token, email) = try await registerTestUser(app: app)

            try await app.testing().test(.POST, "foods", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(makeFoodBody(name: "", kcalPer100g: 950))
            }, afterResponse: { res async in
                #expect(res.status == .badRequest)
            })

            try await deleteTestUser(email: email, on: app.db)
        }
    }
}
