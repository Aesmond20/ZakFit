//
//  Food.swift
//  ZakFitAPI
//
//  Created by Aesmond on 27/11/2026.
//

import Fluent
import Vapor

/// user_id vide = aliment de la base commune ; rempli = aliment personnalisé de cet utilisateur.
final class Food: Model, @unchecked Sendable {
    static let schema = "foods"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    // MARK: - Valeurs nutritionnelles pour 100 g
    @Field(key: "kcal_per_100g")
    var kcalPer100g: Double
    
    @Field(key: "protein_per_100g")
    var proteinPer100g: Double
    
    @Field(key: "carbs_per_100g")
    var carbsPer100g: Double
    
    @Field(key: "fat_per_100g")
    var fatPer100g: Double
    
    @OptionalField(key: "portion_weight_g")
    var portionWeightG: Double?
    
    // MARK: -
    @OptionalParent(key: "user_id")
    var user: User?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, name: String, kcalPer100g: Double, proteinPer100g: Double, carbsPer100g: Double, fatPer100g: Double, portionWeightG: Double? = nil, userID: UUID? = nil) {
        self.id = id
        self.name = name
        self.kcalPer100g = kcalPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.portionWeightG = portionWeightG
        self.$user.id = userID
    }
}

// MARK: - Conversion en DTO
extension Food {
    func toDTO() throws -> FoodDTO {
        FoodDTO(
            id: try requireID(),
            name: name,
            kcalPer100g: kcalPer100g,
            proteinPer100g: proteinPer100g,
            carbsPer100g: carbsPer100g,
            fatPer100g: fatPer100g,
            portionWeightG: portionWeightG,
            isCustom: $user.id != nil
        )
    }
}
