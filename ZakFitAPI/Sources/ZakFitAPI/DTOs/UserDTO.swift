//
//  UserDTO.swift
//  ZakFitAPI
//
//  Created by Aesmond on 25/11/2026.
//

import Vapor

/// Utilisateur renvoyé par l'API
struct UserDTO: Content {
    let id: UUID
    let firstName: String
    let lastName: String
    let email: String
    let birthDate: Date?
    let sex: Sex?
    let heightCm: Int?
    let weightKg: Double?
    let healhGoal: HealthGoal?
}
