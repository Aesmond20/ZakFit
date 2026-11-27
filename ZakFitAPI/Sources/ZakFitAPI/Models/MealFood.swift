//
//  MealFood.swift
//  ZakFitAPI
//
//  Created by Aesmond on 27/11/2026.
//

import Fluent
import Vapor

/// Aliment d'un repas avec sa quantité
final class MealFood: Model, @unchecked Sendable {
    static let schema = "meal_foods"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "meal_id")
    var meal: Meal
    
    @Parent(key: "food_id")
    var food: Food
    
    @Field(key: "quantity")
    var quantity: Double
    
    @Enum(key: "quantity_unit")
    var quantityUnit: QuantityUnit
    
    init() { }
    
    init(id: UUID? = nil, mealID: UUID, foodID: UUID, quantity: Double, quantityUnit: QuantityUnit) {
        self.id = id
        self.$meal.id = mealID
        self.$food.id = foodID
        self.quantity = quantity
        self.quantityUnit = quantityUnit
    }
}

// MARK: - Calculs
extension MealFood {
    /// Valeurs nutritionnelles exactes de la ligne.
    var grams: Double {
        switch quantityUnit {
        case .gram: quantity
        case .unit: quantity * (food.portionWeightG ?? 0)
        }
    }
    
    var nutrition: NutritionDTO {
        NutritionDTO(
            kcal: food.kcalPer100g * grams / 100,
            protein: food.proteinPer100g * grams / 100,
            carbs: food.carbsPer100g * grams / 100,
            fat: food.fatPer100g * grams / 100
        )
    }
    
    func toDTO() throws -> MealFoodDTO {
        MealFoodDTO(
            id: try requireID(),
            foodID: try food.requireID(),
            name: food.name,
            quantity: quantity,
            quantityUnit: quantityUnit,
            grams: grams,
            nutrition: nutrition.rounded()
        )
    }
}
