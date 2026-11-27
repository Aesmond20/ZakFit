//
//  MealControllerTests.swift
//  ZakFitAPI
//
//  Created by Aesmond on 27/11/2026.
//

@testable import ZakFitAPI
import Foundation
import Testing
import Fluent
import VaporTesting

/// Tests de POST /meals, GET /meals?date= et GET /meals/:mealID
@Suite("Repas", .serialized)
struct MealControllerTests {
    
    // Aliments des données fictives
    private let chickenID = UUID(uuidString: "f00d0000-0000-4000-8000-000000000001")!   // pas de portion
    private let eggID = UUID(uuidString: "f00d0000-0000-4000-8000-000000000006")!       // portion 60 g
    private let riceID = UUID(uuidString: "f00d0000-0000-4000-8000-000000000008")!
    private let appleID = UUID(uuidString: "f00d0000-0000-4000-8000-00000000001c")!     // portion 150 g
    private let grannyCakeID = UUID(uuidString: "f00d0000-0000-4000-8000-00000000002d")! // aliment perso d'Ambre
    
    private func date(_ iso: String) throws -> Date {
        try #require(ISO8601DateFormatter().date(from: iso))
    }
    
    private func lunchBody() throws -> CreateMealDTO {
        CreateMealDTO(type: .lunch, eatenAt: try date("2026-11-27T11:30:00Z"), foods: [
            MealFoodInputDTO(foodID: chickenID, quantity: 150, quantityUnit: .gram),
            MealFoodInputDTO(foodID: riceID, quantity: 200, quantityUnit: .gram),
            MealFoodInputDTO(foodID: eggID, quantity: 2, quantityUnit: .unit),
        ])
    }
    
    private func createMeal(_ body: CreateMealDTO, token: String, app: Application) async throws -> MealDTO {
        var meal: MealDTO?
        try await app.testing().test(.POST, "meals", beforeRequest: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: token)
            try req.content.encode(body)
        }, afterResponse: { res async throws in
            #expect(res.status == .created)
            meal = try res.content.decode(MealDTO.self)
        })
        return try #require(meal)
    }
    
    private func expectBadRequest(_ body: CreateMealDTO, reason: String, app: Application) async throws {
        let (token, email) = try await registerTestUser(app: app)
        try await app.testing().test(.POST, "meals", beforeRequest: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: token)
            try req.content.encode(body)
        }, afterResponse: { res async in
            #expect(res.status == .badRequest)
            #expect(res.body.string.contains(reason))
        })
        try await deleteTestUser(email: email, on: app.db)
    }
    
    // MARK: - POST /meals
    @Test("201 : crée le repas et calcule les totaux côté serveur")
    func createComputesTotals() async throws {
        try await withTestApp { app in
            let (token, email) = try await registerTestUser(app: app)
            
            let meal = try await createMeal(try lunchBody(), token: token, app: app)
            #expect(meal.type == .lunch)
            #expect(meal.foods.count == 3)
            #expect(meal.totals == NutritionDTO(kcal: 682, protein: 67, carbs: 56.8, fat: 18))
            
            let egg = try #require(meal.foods.first { $0.foodID == eggID })
            #expect(egg.grams == 120)
            #expect(egg.nutrition.kcal == 174)
            
            try await deleteTestUser(email: email, on: app.db)
        }
    }
    
    @Test("400 : quantité en unités pour un aliment sans poids de portion")
    func createRejectsUnitWithoutPortion() async throws {
        try await withTestApp { app in
            let body = CreateMealDTO(type: .dinner, eatenAt: Date(), foods: [
                MealFoodInputDTO(foodID: chickenID, quantity: 1, quantityUnit: .unit)
            ])
            try await expectBadRequest(body, reason: "no portion weight", app: app)
        }
    }
    
    @Test("400 : aliment inconnu")
    func createRejectsUnknownFood() async throws {
        try await withTestApp { app in
            let unknownID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
            let body = CreateMealDTO(type: .dinner, eatenAt: Date(), foods: [
                MealFoodInputDTO(foodID: unknownID, quantity: 100, quantityUnit: .gram)
            ])
            try await expectBadRequest(body, reason: "Unknown food", app: app)
        }
    }
    
    @Test("400 : aliment perso d'un autre utilisateur")
    func createRejectsOtherUsersFood() async throws {
        try await withTestApp { app in
            let body = CreateMealDTO(type: .snack, eatenAt: Date(), foods: [
                MealFoodInputDTO(foodID: grannyCakeID, quantity: 1, quantityUnit: .unit)
            ])
            try await expectBadRequest(body, reason: "Unknown food", app: app)
        }
    }
    
    @Test("400 : le même aliment deux fois")
    func createRejectsDuplicateFood() async throws {
        try await withTestApp { app in
            let body = CreateMealDTO(type: .lunch, eatenAt: Date(), foods: [
                MealFoodInputDTO(foodID: riceID, quantity: 100, quantityUnit: .gram),
                MealFoodInputDTO(foodID: riceID, quantity: 50, quantityUnit: .gram),
            ])
            try await expectBadRequest(body, reason: "only appear once", app: app)
        }
    }
    
    @Test("400 : repas sans aliment")
    func createRejectsEmptyFoods() async throws {
        try await withTestApp { app in
            let body = CreateMealDTO(type: .lunch, eatenAt: Date(), foods: [])
            try await expectBadRequest(body, reason: "foods", app: app)
        }
    }
    
    // MARK: - GET /meals?date=
    @Test("200 : les repas sont regroupés par jour en heure de Paris")
    func listGroupsByParisDay() async throws {
        try await withTestApp { app in
            let (token, email) = try await registerTestUser(app: app)
            
            // 23 h 30 UTC le 20/11 = 0 h 30 le 21/11 à Paris
            let snack = CreateMealDTO(type: .snack, eatenAt: try date("2026-11-20T23:30:00Z"), foods: [
                MealFoodInputDTO(foodID: appleID, quantity: 1, quantityUnit: .unit)
            ])
            _ = try await createMeal(snack, token: token, app: app)
            
            try await app.testing().test(.GET, "meals?date=2026-11-21", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let day = try res.content.decode(DayMealsDTO.self)
                #expect(day.date == "2026-11-21")
                #expect(day.meals.count == 1)
                #expect(day.totals.kcal == 78)   // 1 pomme = 150 g × 52 kcal / 100
            })
            
            try await app.testing().test(.GET, "meals?date=2026-11-20", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                let day = try res.content.decode(DayMealsDTO.self)
                #expect(day.meals.isEmpty)
                #expect(day.totals == .zero)
            })
            
            try await deleteTestUser(email: email, on: app.db)
        }
    }
    
    @Test("400 : date au mauvais format")
    func listRejectsInvalidDate() async throws {
        try await withTestApp { app in
            let token = try await loginToken(email: "hugo.bernard@email.fr", app: app)
            
            try await app.testing().test(.GET, "meals?date=27-11-2026", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async in
                #expect(res.status == .badRequest)
                #expect(res.body.string.contains("YYYY-MM-DD"))
            })
        }
    }
    
    @Test("401 : sans token")
    func listRejectsMissingToken() async throws {
        try await withTestApp { app in
            try await app.testing().test(.GET, "meals", beforeRequest: { _ in
            }, afterResponse: { res async in
                #expect(res.status == .unauthorized)
            })
        }
    }
    
    // MARK: - GET /meals/:mealID
    @Test("200 puis 404 : un repas n'est visible que par son propriétaire")
    func findIsLimitedToOwner() async throws {
        try await withTestApp { app in
            let (token, email) = try await registerTestUser(app: app)
            let meal = try await createMeal(try lunchBody(), token: token, app: app)
            
            try await app.testing().test(.GET, "meals/\(meal.id)", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let found = try res.content.decode(MealDTO.self)
                #expect(found.id == meal.id)
                #expect(found.totals.kcal == 682)
            })
            
            let hugoToken = try await loginToken(email: "hugo.bernard@email.fr", app: app)
            try await app.testing().test(.GET, "meals/\(meal.id)", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: hugoToken)
            }, afterResponse: { res async in
                #expect(res.status == .notFound)
            })
            
            try await deleteTestUser(email: email, on: app.db)
        }
    }
    
    @Test("400 : id qui n'est pas un UUID")
    func findRejectsInvalidID() async throws {
        try await withTestApp { app in
            let token = try await loginToken(email: "hugo.bernard@email.fr", app: app)
            
            try await app.testing().test(.GET, "meals/abc", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async in
                #expect(res.status == .badRequest)
            })
        }
    }
}
