//
//  CreateMealDTO.swift
//  ZakFitAPI
//
//  Created by Aesmond on 27/11/2026.
//

import Vapor

/// POST /meals
struct CreateMealDTO: Content, Validatable {
    let type: MealType
    let eatenAt: Date
    let foods: [MealFoodInputDTO]
    
    static func validations(_ validations: inout Validations) {
        validations.add("foods", as: [MealFoodInputDTO].self, is: !.empty && .count(...30))
    }
    
    /// Quantités valides et chaque aliment une seule fois (uq_meal_foods_meal_id_food_id)
    func ensureFoodsAreValid() throws {
        guard foods.allSatisfy({ (0.1...5000).contains($0.quantity) }) else {
            throw Abort(.badRequest, reason: "Quantity must be between 0.1 and 5000")
        }
        guard Set(foods.map(\.foodID)).count == foods.count else {
            throw Abort(.badRequest, reason: "Each food can only appear once in a meal")
        }
    }
}
