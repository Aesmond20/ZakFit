//
//  RegisterUserDTO.swift
//  ZakFitAPI
//
//  Created by Aesmond on 25/11/2026.
//

import Vapor

/// Corps de POST /auth/register.
struct RegisterUserDTO: Content, Validatable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    let confirmPassword: String
    
    static func validations(_ validations: inout Validations) {
        validations.add("firstName", as: String.self, is: !.empty && .count(...50))
        validations.add("lastName", as: String.self, is: !.empty && .count(...50))
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...72))
        validations.add("confirmPassword", as: String.self, is: !.empty)
    }
    
    /// Règle qui compare les deux Password
    func ensurePasswordsMatch() throws {
        guard password == confirmPassword else {
            throw Abort(.badRequest, reason: "Passwords do not match")
        }
    }
    
    /// Le mot de passe est haché avant d'arriver ici : le modèle ne voit jamais le mot de passe en clair.
    func toModel(passwordHash: String) -> User {
        User(
            firstName: firstName,
            lastName: lastName,
            email: email.lowercased(),
            passwordHash: passwordHash
        )
    }
}
