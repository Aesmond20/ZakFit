//
//  NutritionDTO.swift
//  ZakFitAPI
//
//  Created by Aesmond on 27/11/2026.
//

import Vapor

/// Calories (kcal) et macronutriments (g)
struct NutritionDTO: Content, Equatable {
    var kcal: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    
    static let zero = NutritionDTO(kcal: 0, protein: 0, carbs: 0, fat: 0)
    
    static func + (lhs: NutritionDTO, rhs: NutritionDTO) -> NutritionDTO {
        NutritionDTO(
            kcal: lhs.kcal + rhs.kcal,
            protein: lhs.protein + rhs.protein,
            carbs: lhs.carbs + rhs.carbs,
            fat: lhs.fat + rhs.fat
        )
    }
    
    /// Arrondi d'affichage : kcal à l'unité, macros au dixième.
    func rounded() -> NutritionDTO {
        NutritionDTO(
            kcal: kcal.rounded(),
            protein: (protein * 10).rounded() / 10,
            carbs: (carbs * 10).rounded() / 10,
            fat: (fat * 10).rounded() / 10
        )
    }
}
