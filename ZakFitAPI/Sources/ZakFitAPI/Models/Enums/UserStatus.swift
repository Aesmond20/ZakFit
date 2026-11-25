//
//  UserStatus.swift
//  ZakFitAPI
//
//  Created by Aesmond on 25/11/2026.
//

/// État du compte. Le blocage est prévu en V2.
enum UserStatus: String, Codable, CaseIterable {
    case active
    case blocked
}
