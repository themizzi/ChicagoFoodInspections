import Foundation
import Combine

enum AppState {
    case loading
    case loaded([Inspection])
    case error(Error)
}

enum AppInput {
    case load([Inspection])
    case showError(Error)
    case refresh
}

struct AppTransition {
    let input: AppInput?
    let state: AppState
}

struct Inspection {
    var title: String
    var address: String
    var inspectionDate: Date?
}

protocol AppAction {
    func callAsFunction(_ send: @escaping (AppInput) -> Void)
}

class AppModel {
    private let stateSubject: CurrentValueSubject<AppTransition, Never>
    private let loadingActions: [AppAction]
    private var cancellables: Set<AnyCancellable> = []
    
    var statePublisher: AnyPublisher<AppTransition, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    init(
        stateSubject: CurrentValueSubject<AppTransition, Never>,
        loadingActions: [AppAction] = []
    ) {
        self.stateSubject = stateSubject
        self.loadingActions = loadingActions
        
        self.stateSubject.receive(on: DispatchQueue.main).sink { state in
            if case .loading = state.state {
                self.loadingActions.forEach { $0(self.send) }
            }
        }.store(in: &cancellables)
    }
    
    public func send(input: AppInput) {
        let newState: AppState
        switch (stateSubject.value.state, input) {
        case (.loading, .showError(let error)):
            newState = .error(error)
        case (.loading, .load(let inspections)):
            newState = .loaded(inspections)
        case (.loaded, .refresh),
            (.error, .refresh):
            newState = .loading
        default:
            return
        }
        stateSubject.send(.init(input: input, state: newState))
    }
}
