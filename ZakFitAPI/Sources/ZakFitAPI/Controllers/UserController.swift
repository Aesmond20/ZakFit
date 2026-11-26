//
//  UserController.swift
//  ZakFitAPI
//
//  Created by Aesmond on 26/11/2026.
//

import Fluent
import Vapor

/// Routes du profil de l'utilisateur connecté
struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("users")
        
        users.group("me") { user in
            user.get(use: me)
            user.put(use: update)
        }
    }
    
    /// GET /users/me : profil complet de l'utilisateur connecté, avec ses préférences
    @Sendable
    func me(req: Request) async throws -> UserDTO {
        let user = try await req.auth.require(UserPayload.self).findUser(on: req.db)
        try await user.$dietaryPreferences.load(on: req.db)
        
        return try user.toDTO()
    }
    
    /// PUT /users/me : remplace le profil de l'utilisateur connecté
    @Sendable
    func update(req: Request) async throws -> UserDTO {
        try UpdateUserDTO.validate(content: req)
        let dto = try req.content.decode(UpdateUserDTO.self)
        try dto.ensurePasswordsMatch()
        try dto.ensureBirthDateIsInPast()
        
        let user = try await req.auth.require(UserPayload.self).findUser(on: req.db)
        let userID = try user.requireID()
        
        let email = dto.email.lowercased()
        let otherUser = try await User.query(on: req.db)
            .filter(\.$email == email)
            .filter(\.$id != userID)
            .first()
        guard otherUser == nil else {
            throw Abort(.conflict, reason: "Email already used")
        }
        
        let preferenceNames = Set(dto.dietaryPreferences)
        var preferences: [DietaryPreference] = []
        if !preferenceNames.isEmpty {
            preferences = try await DietaryPreference.query(on: req.db)
                .filter(\.$name ~~ Array(preferenceNames))
                .all()
        }
        guard preferences.count == preferenceNames.count else {
            throw Abort(.badRequest, reason: "Unknown dietary preference")
        }
        
        user.firstName = dto.firstName
        user.lastName = dto.lastName
        user.email = email
        user.birthDate = dto.birthDate
        user.sex = dto.sex
        user.heightCm = dto.heightCm
        user.weightKg = dto.weightKg
        if let password = dto.password {
            user.passwordHash = try await req.password.async.hash(password)
        }
        try await user.save(on: req.db)
        
        try await user.$dietaryPreferences.detachAll(on: req.db)
        try await user.$dietaryPreferences.attach(preferences, on: req.db)
        try await user.$dietaryPreferences.load(on: req.db)
        
        return try user.toDTO()
    }
}
