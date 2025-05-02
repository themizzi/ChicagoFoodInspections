//
//  MockInspectionsLoader.swift
//  ChicagoFoodInspections
//
//  Created by Joe Mizzi on 5/1/25.
//

import Foundation

class FakeInspectionsLoader: InspectionsLoader {
    private let errorRate: Double
    
    init(errorRate: Double = 0) {
        self.errorRate = errorRate
    }
    
    func callAsFunction() throws -> [Inspection] {
        let shouldThrowError = Double.random(in: 0...1) < errorRate
        
        if shouldThrowError {
            throw NSError(domain: "FakeInspectionsLoader", code: 1, userInfo: nil)
        }
        
        let calendar = Calendar.current
        let today = Calendar.current.startOfDay(for: Date())
        
        return [
            Inspection(title: "Inspection 1", address: "1 N State St", inspectionDate: today),
            Inspection(title: "Inspection 2", address: "200 S Michigan Ave", inspectionDate: calendar.date(byAdding: .day, value: -20, to: today) ?? today),
            Inspection(title: "Inspection 3", address: "800 W North Ave", inspectionDate: calendar.date(byAdding: .day, value: -20, to: today) ?? today),
            Inspection(title: "Inspection 4", address: "800 W North Ave", inspectionDate: calendar.date(byAdding: .day, value: -40, to: today) ?? today),
        ]
    }
}
