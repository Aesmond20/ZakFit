//
//  UpdateUserDTO.swift
//  ZakFitAPI
//
//  Created by Aesmond on 26/11/2026.
//

import Vapor

/// PUT /users/me
struct UpdateUserDTO: Content, Validatable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String?
    let confirmPassword: String?
    let birthDate: Date?
    let sex: Sex?
    let heightCm: Int?
    let weightKg: Double?
    let healthGoal: HealthGoal?
    let dietaryPreferences: [String]
    
    static func validations(_ validations: inout Validations) {
            validations.add("firstName", as: String.self, is: !.empty && .count(...50))
            validations.add("lastName", as: String.self, is: !.empty && .count(...50))
            validations.add("email", as: String.self, is: .email)
            validations.add("password", as: String?.self, is: .nil || .count(8...72), required: false)
            validations.add("heightCm", as: Int?.self, is: .nil || .range(100...250), required: false)
            validations.add("weightKg", as: Double?.self, is: .nil || .range(30.0...300.0), required: false)
        }
    
    func ensurePasswordsMatch() throws {
        guard password == confirmPassword else {
            throw Abort(.badRequest, reason: "Passwords do not match")
        }
    }
    
    func ensureBirthDateIsInPast() throws {
        if let birthDate, birthDate >= Date() {
            throw Abort(.badRequest, reason: "Birth date must be in the past")
        }
    }
}
