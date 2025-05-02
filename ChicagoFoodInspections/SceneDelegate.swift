import UIKit
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private var cancellables: Set<AnyCancellable> = []

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let stateSubject = CurrentValueSubject<AppTransition, Never>(.init(input: nil, state: .loading))
        let jsonDecoder: JSONDecoder = .init()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: -18000)!
        jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
        #if USE_FAKES
        let loader = FakeInspectionsLoader(errorRate: 0.5)
        #else
        let loader = SODAInspectionsLoader(urlSession: URLSession.shared, decoder: jsonDecoder, baseURL: URL(string: "https://data.cityofchicago.org/resource/4ijn-s7e5.json")!)
        #endif
        let machine = AppModel(stateSubject: stateSubject, loadingActions: [
            LoadingAction(inspectionsLoader: loader)
        ])
        
        stateSubject.print("App State", to: nil).sink { _ in }.store(in: &cancellables)
        
        let rootViewController = AppViewController(machine: machine)
        let navigationViewController = UINavigationController(rootViewController: rootViewController)
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationViewController
        self.window = window
        window.makeKeyAndVisible()
    }
}
