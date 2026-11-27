//
//  DayMealsDTO.swift
//  ZakFitAPI
//
//  Created by Aesmond on 27/11/2026.
//

import Vapor

/// Repas d'un jour et totaux de la journée
struct DayMealsDTO: Content {
    let date: String
    let meals: [MealDTO]
    let totals: NutritionDTO
}
