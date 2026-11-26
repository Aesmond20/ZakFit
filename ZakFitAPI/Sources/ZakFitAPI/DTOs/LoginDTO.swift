//
//  LoginDTO.swift
//  ZakFitAPI
//
//  Created by Aesmond on 26/11/2026.
//

import Vapor

/// POST /auth/login.
struct LoginDTO: Content, Validatable {
    let email: String
    let password: String
    
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: !.empty)
    }
}
