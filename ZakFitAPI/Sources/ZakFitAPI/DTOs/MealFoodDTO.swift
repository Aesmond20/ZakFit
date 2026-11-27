//
//  MealFoodDTO.swift
//  ZakFitAPI
//
//  Created by Aesmond on 27/11/2026.
//

import Vapor

/// Ligne d'un repas renvoyée par l'API
struct MealFoodDTO: Content {
    let id: UUID
    let foodID: UUID
    let name: String
    let quantity: Double
    let quantityUnit: QuantityUnit
    let grams: Double
    let nutrition: NutritionDTO
}
