//
//  AuthController.swift
//  ZakFitAPI
//
//  Created by Aesmond on 25/11/2026.
//

import Fluent
import JWT
import Vapor

/// Routes d'authentification
struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("register", use: register)
    }
    
    /// POST /auth/register : crée le compte
    @Sendable
    func register(req:Request) async throws -> Response {
        try RegisterUserDTO.validate(content: req)
        let dto = try req.content.decode(RegisterUserDTO.self)
        try dto.ensurePasswordsMatch()
        
        let emailAlreadyUsed = try await User.query(on: req.db)
            .filter(\.$email == dto.email.lowercased())
            .first() != nil
        guard !emailAlreadyUsed else {
            throw Abort(.conflict, reason: "Email already used")
        }
        
        let passwordHash = try await req.password.async.hash(dto.password)
        let user = dto.toModel(passwordHash: passwordHash)
        try await user.save(on: req.db)
        
        let token = try await req.jwt.sign(UserPayload(user: user))
        let response = AuthResponseDTO(token: token, user: try user.toDTO())
        return try await response.encodeResponse(status: .created, for: req)
    }
}
