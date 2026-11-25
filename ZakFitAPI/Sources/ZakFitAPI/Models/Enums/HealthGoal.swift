//
//  HealthGoal.swift
//  ZakFitAPI
//
//  Created by Aesmond on 25/11/2026.
//

/// Objectif de santé choisi dans le profil
enum HealthGoal: String, Codable, CaseIterable {
    case loseWeight = "lose_weight"
    case maintain
    case gainMuscle = "gain_muscle"
}
