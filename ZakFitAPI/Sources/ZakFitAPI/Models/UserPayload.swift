//
//  UserPayload.swift
//  ZakFitAPI
//
//  Created by Aesmond on 25/11/2026.
//

import Fluent
import JWT
import Vapor

/// Contenu du token JWT
struct UserPayload: JWTPayload, Authenticatable {
    var subject: SubjectClaim
    var expiration: ExpirationClaim
    
    /// Token valable 7 jours
    init(user: User) throws {
        let now = Date()
        guard let expiresAt = Calendar(identifier: .gregorian).date(byAdding: .day, value: 7, to: now) else {
            throw Abort(.internalServerError, reason: "Unable to compute token expiration")
        }
        self.subject = SubjectClaim(value: try user.requireID().uuidString)
        self.expiration = ExpirationClaim(value: expiresAt)
    }
    
    /// Appelée automatiquement à chaque requête protégée : refuse un token expiré.
    func verify(using algorithm: some JWTAlgorithm) async throws {
        try expiration.verifyNotExpired()
    }
}
