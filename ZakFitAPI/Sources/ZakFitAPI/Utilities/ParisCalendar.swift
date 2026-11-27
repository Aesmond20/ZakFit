//
//  ParisCalendar.swift
//  ZakFitAPI
//
//  Created by Aesmond on 27/11/2026.
//

import Foundation
import Vapor

/// Les dates sont enregistrées en UTC
enum ParisCalendar {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris") ?? .current
        return calendar
    }
    
    /// Lit et écrit les dates au format "2026-11-27", en heure de Paris
    private static func dayFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter
    }

    static func dayRange(for day: String) throws -> (start: Date, end: Date) {
        guard let start = dayFormatter().date(from: day),
              let end = calendar.date(byAdding: .day, value: 1, to: start)
        else {
            throw Abort(.badRequest, reason: "Date must use the format YYYY-MM-DD")
        }
        return (start, end)
    }

    static func today() -> String {
        dayFormatter().string(from: Date())
    }
}
