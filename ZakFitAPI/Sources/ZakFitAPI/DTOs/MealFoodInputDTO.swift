//
//  MealFoodInputDTO.swift
//  ZakFitAPI
//
//  Created by Aesmond on 27/11/2026.
//

import Vapor

/// Aliment d'un repas envoyé par l'app
struct MealFoodInputDTO: Content {
    let foodID: UUID
    let quantity: Double
    let quantityUnit: QuantityUnit
}
