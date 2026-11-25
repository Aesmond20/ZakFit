//
//  AuthResponseDTO.swift
//  ZakFitAPI
//
//  Created by Aesmond on 25/11/2026.
//

import Vapor

/// Réponse de l'inscription et de la connexion.
struct AuthResponseDTO: Content {
    let token: String
    let user: UserDTO
}
