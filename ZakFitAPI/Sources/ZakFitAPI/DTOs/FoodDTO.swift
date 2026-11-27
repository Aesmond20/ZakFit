//
//  FoodDTO.swift
//  ZakFitAPI
//
//  Created by Aesmond on 27/11/2026.
//

import Vapor

struct FoodDTO: Content {
    let id: UUID
    let name: String
    let kcalPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let portionWeightG: Double?
    let isCustom: Bool
}
