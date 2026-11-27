//
//  Meal.swift
//  ZakFitAPI
//
//  Created by Aesmond on 27/11/2026.
//

import Fluent
import Vapor

/// Les totaux (kcal, macros) ne sont pas stockés : ils sont recalculés à partir des aliments.
final class Meal: Model, @unchecked Sendable {
    static let schema = "meals"
    
    @ID(key: .id)
    var id: UUID?
    
    @Enum(key: "type")
    var type: MealType
    
    @Field(key: "eaten_at")
    var eatenAt: Date
    
    @Parent(key: "user_id")
    var user: User
    
    @Children(for: \.$meal)
    var mealFoods: [MealFood]
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, type: MealType, eatenAt: Date, userID: UUID) {
        self.id = id
        self.type = type
        self.eatenAt = eatenAt
        self.$user.id = userID
    }
}
