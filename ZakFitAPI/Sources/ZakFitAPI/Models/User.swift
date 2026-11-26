//
//  User.swift
//  ZakFitAPI
//
//  Created by Aesmond on 25/11/2026.
//

import Fluent
import Vapor

/// Utilisateur de ZakFit (table users).
/// La table est créée par le script SQL : aucune migration Fluent.
final class User: Model, @unchecked Sendable {
    static let schema = "users"
    
    // MARK: - Identité et connexion
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "first_name")
    var firstName: String
    
    @Field(key: "last_name")
    var lastName: String
    
    @Field(key: "email")
    var email: String
    
    /// Mot de passe haché avec bcrypt, jamais renvoyé par l'API.
    @Field(key: "password_hash")
    var passwordHash: String
    
    // MARK: - Profil (rempli après l'inscription)
    @OptionalField(key: "birth_date")
    var birthDate: Date?
    
    @OptionalEnum(key: "sex")
    var sex: Sex?
    
    @OptionalField(key: "height_cm")
    var heightCm: Int?
    
    @OptionalField(key: "weight_kg")
    var weightKg: Double?
    
    @OptionalEnum(key: "health_goal")
    var healthGoal: HealthGoal?
    
    @Siblings(through: UserDietaryPreference.self, from: \.$user, to: \.$dietaryPreference)
    var dietaryPreferences: [DietaryPreference]
    
    // MARK: - Compte (V2 : administration)
    @Enum(key: "role")
    var role: UserRole
    
    @Enum(key: "status")
    var status: UserStatus
    
    // MARK: - Dates techniques
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    // MARK: - Constructeurs
    init() { }
    
    /// Création à l'inscription
    init(id: UUID? = nil, firstName: String, lastName: String, email: String, passwordHash: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.passwordHash = passwordHash
        self.role = .user
        self.status = .active
    }
}

// MARK: - Conversion en DTO
extension User {
    func toDTO() throws -> UserDTO {
        UserDTO(
            id: try requireID(),
            firstName: firstName,
            lastName: lastName,
            email: email,
            birthDate: birthDate,
            sex: sex,
            heightCm: heightCm,
            weightKg: weightKg,
            healthGoal: healthGoal,
            dietaryPreferences: $dietaryPreferences.value?.map(\.name).sorted() ?? []
        )
    }
}
