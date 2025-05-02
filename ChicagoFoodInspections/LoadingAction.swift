//
//  LoadingAction.swift
//  ChicagoFoodInspections
//
//  Created by Joe Mizzi on 5/1/25.
//

import Foundation

protocol InspectionsLoader {
    func callAsFunction() async throws -> [Inspection]
}

class LoadingAction: AppAction {
    private let inspectionsLoader: InspectionsLoader
    
    init(inspectionsLoader: InspectionsLoader) {
        self.inspectionsLoader = inspectionsLoader
    }
    
    func callAsFunction(_ send: @escaping (AppInput) -> Void) {
        Task {
            do {
                let inspections = try await self.inspectionsLoader()
                send(.load(inspections))
            } catch {
                send(.showError(error))
            }
        }
    }
}
