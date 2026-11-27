//
//  CreateFoodDTO.swift
//  ZakFitAPI
//
//  Created by Aesmond on 27/11/2026.
//

import Vapor

/// POST /foods : aliment personnalisé
struct CreateFoodDTO: Content, Validatable {
    let name: String
    let kcalPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let portionWeightG: Double?
    
    static func validations(_ validations: inout Validations) {
            validations.add("name", as: String.self, is: !.empty && .count(...100))
            validations.add("kcalPer100g", as: Double.self, is: .range(0.0...900.0))
            validations.add("proteinPer100g", as: Double.self, is: .range(0.0...100.0))
            validations.add("carbsPer100g", as: Double.self, is: .range(0.0...100.0))
            validations.add("fatPer100g", as: Double.self, is: .range(0.0...100.0))
            validations.add("portionWeightG", as: Double?.self, is: .nil || .range(0.1...2000.0), required: false)
        }
    
    /// 100 g d'aliment ne peuvent pas contenir plus de 100 g de macros
    func ensureMacrosFitIn100g() throws {
        guard proteinPer100g + carbsPer100g + fatPer100g <= 100 else {
            throw Abort(.badRequest, reason: "Protein, carbs and fat cannot exceed 100 g per 100 g")
        }
    }
    
    func toModel(userID: UUID) -> Food {
        Food(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            kcalPer100g: kcalPer100g,
            proteinPer100g: proteinPer100g,
            carbsPer100g: carbsPer100g,
            fatPer100g: fatPer100g,
            portionWeightG: portionWeightG,
            userID: userID
        )
    }
}
