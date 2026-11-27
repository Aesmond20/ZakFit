//
//  FoodController.swift
//  ZakFitAPI
//
//  Created by Aesmond on 27/11/2026.
//

import Fluent
import Vapor

/// Routes des aliments de l'utilisateur connecté
struct FoodController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let foods = routes.grouped("foods")
        
        foods.get(use: search)
        foods.post(use: create)
    }
    
    /// GET /foods?search=riz
    @Sendable
    func search(req: Request) async throws -> [FoodDTO] {
        let user = try await req.auth.require(UserPayload.self).findUser(on: req.db)
        let userID = try user.requireID()
        let search = (req.query[String.self, at: "search"] ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let query = Food.query(on: req.db)
            .visible(to: userID)
        
        if !search.isEmpty {
            query.filter(\.$name ~~ search)
        }
        
        let foods = try await query
            .sort(\.$name)
            .limit(50)
            .all()
        
        return try foods.map { try $0.toDTO() }
    }
    
    /// POST /foods : crée un aliment personnalisé
    @Sendable
    func create(req: Request) async throws -> Response {
        try CreateFoodDTO.validate(content: req)
        let dto = try req.content.decode(CreateFoodDTO.self)
        try dto.ensureMacrosFitIn100g()
        
        let user = try await req.auth.require(UserPayload.self).findUser(on: req.db)
        let food = dto.toModel(userID: try user.requireID())
        try await food.save(on: req.db)
        
        return try await food.toDTO().encodeResponse(status: .created, for: req)
    }
}
