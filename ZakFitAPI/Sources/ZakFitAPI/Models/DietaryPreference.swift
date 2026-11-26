//
//  DietaryPreference.swift
//  ZakFitAPI
//
//  Created by Aesmond on 26/11/2026.
//

import Fluent
import Vapor

/// Préférence alimentaire
final class DietaryPreference: Model, @unchecked Sendable {
    static let schema = "dietary_preferences"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    init() { }
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
