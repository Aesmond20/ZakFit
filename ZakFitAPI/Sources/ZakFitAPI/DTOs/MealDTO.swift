//
//  MealDTO.swift
//  ZakFitAPI
//
//  Created by Aesmond on 27/11/2026.
//

import Vapor

/// Repas renvoyé par l'API, avec ses aliments et ses totaux
struct MealDTO: Content {
    let id: UUID
    let type: MealType
    let eatenAt: Date
    let foods: [MealFoodDTO]
    let totals: NutritionDTO
}
