//
//  MealController.swift
//  ZakFitAPI
//
//  Created by Aesmond on 27/11/2026.
//

import Fluent
import Vapor

/// Routes des repas de l'utilisateur connecté
struct MealController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let meals = routes.grouped("meals")
        
        meals.get(use: listByDay)
        meals.post(use: create)
        
        meals.group(":mealID") { meal in
            meal.get(use: find)
        }
    }
    
    /// GET /meals?date=2026-11-27
    @Sendable
    func listByDay(req: Request) async throws -> DayMealsDTO {
        let user = try await req.auth.require(UserPayload.self).findUser(on: req.db)
        let day = req.query[String.self, at: "date"] ?? ParisCalendar.today()
        let range = try ParisCalendar.dayRange(for: day)
        
        let meals = try await Meal.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .filter(\.$eatenAt >= range.start)
            .filter(\.$eatenAt < range.end)
            .with(\.$mealFoods) { mealFood in mealFood.with(\.$food) }
            .sort(\.$eatenAt)
            .all()
        
        let totals = meals.reduce(NutritionDTO.zero) { $0 + $1.nutrition }
        return DayMealsDTO(date: day, meals: try meals.map { try $0.toDTO() }, totals: totals.rounded())
    }
    
    /// GET /meals/:mealID : détail d'un repas de l'utilisateur
    @Sendable
    func find(req: Request) async throws -> MealDTO {
        let user = try await req.auth.require(UserPayload.self).findUser(on: req.db)
        let meal = try await loadMeal(id: mealID(from: req), userID: user.requireID(), on: req.db)
        
        return try meal.toDTO()
    }
    
    /// POST /meals
    @Sendable
    func create(req: Request) async throws -> Response {
        try CreateMealDTO.validate(content: req)
        let dto = try req.content.decode(CreateMealDTO.self)
        try dto.ensureFoodsAreValid()
        
        let user = try await req.auth.require(UserPayload.self).findUser(on: req.db)
        let userID = try user.requireID()
        try await checkFoods(dto.foods, userID: userID, on: req.db)
        
        // Le repas et ses lignes sont enregistrés ensemble, ou pas du tout
        let meal = Meal(type: dto.type, eatenAt: dto.eatenAt, userID: userID)
        try await req.db.transaction { db in
            try await meal.save(on: db)
            let mealID = try meal.requireID()
            let mealFoods = dto.foods.map {
                MealFood(mealID: mealID, foodID: $0.foodID, quantity: $0.quantity, quantityUnit: $0.quantityUnit)
            }
            try await mealFoods.create(on: db)
        }
        
        let created = try await loadMeal(id: meal.requireID(), userID: userID, on: req.db)
        return try await created.toDTO().encodeResponse(status: .created, for: req)
    }
    
    private func mealID(from req: Request) throws -> UUID {
        guard let id = req.parameters.get("mealID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid meal ID")
        }
        return id
    }
    
    private func loadMeal(id: UUID, userID: UUID, on db: any Database) async throws -> Meal {
        let meal = try await Meal.query(on: db)
            .filter(\.$id == id)
            .filter(\.$user.$id == userID)
            .with(\.$mealFoods) { mealFood in mealFood.with(\.$food) }
            .first()
        
        guard let meal else {
            throw Abort(.notFound, reason: "Meal not found")
        }
        return meal
    }
    
    private func checkFoods(_ items: [MealFoodInputDTO], userID: UUID, on db: any Database) async throws {
        let foods = try await Food.query(on: db)
            .filter(\.$id ~~ items.map(\.foodID))
            .visible(to: userID)
            .all()
        guard foods.count == items.count else {
            throw Abort(.badRequest, reason: "Unknown food")
        }
        
        let unitFoodIDs = Set(items.filter { $0.quantityUnit == .unit }.map(\.foodID))
        let foodsWithoutPortion = foods.filter { food in
            guard let id = food.id else { return false }
            return unitFoodIDs.contains(id) && food.portionWeightG == nil
        }
        guard foodsWithoutPortion.isEmpty else {
            throw Abort(.badRequest, reason: "This food has no portion weight: use grams")
        }
    }
}

