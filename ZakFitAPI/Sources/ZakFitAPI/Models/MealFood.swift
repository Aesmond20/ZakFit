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
