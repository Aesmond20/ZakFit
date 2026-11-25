//
//  UserRole.swift
//  ZakFitAPI
//
//  Created by Aesmond on 25/11/2026.
//

/// Rôle du compte. L'administration est prévue en V2.
enum UserRole: String, Codable, CaseIterable {
    case user
    case admin
}
