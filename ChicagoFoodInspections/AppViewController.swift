import UIKit
import Combine

class AppViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private lazy var refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshButtonTapped))
    private let mainView = AppView()
    private let viewModel: AppModel
    private var groupedInspections: [(date: Date, inspections: [Inspection])] = []
    private var cancellables: Set<AnyCancellable> = []

    init(machine: AppModel) {
        self.viewModel = machine
        super.init(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        view = mainView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainView.tableView.delegate = self
        mainView.tableView.dataSource = self
        
        title = "Chicago Food Inspections"
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = refreshButton
        
        // Bind loading spinner
        self.viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .map { transition in
                if case .loading = transition.state {
                    return false
                } else {
                    return true
                }
            }.assign(to: \.isHidden, on: mainView.activityIndicator)
            .store(in: &cancellables)
        
        // Bind error label hidden
        self.viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .map { transition in
                if case .error = transition.state {
                    return false
                } else {
                    return true
                }
            }
            .assign(to: \.isHidden, on: mainView.errorLabel)
            .store(in: &cancellables)
        
        // Bind error label text
        self.viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .map { transition in
                if case .error(let error) = transition.state {
                    return error.localizedDescription
                } else {
                    return ""
                }
            }
            .assign(to: \.text, on: mainView.errorLabel)
            .store(in: &cancellables)
        
        // Bind tableView hidden
        self.viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .map { transition in
                if case .loaded = transition.state {
                    return false
                } else {
                    return true
                }
            }
            .assign(to: \.isHidden, on: mainView.tableView)
            .store(in: &cancellables)
        
        // Bind refreshButton enabled
        self.viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .map { transition in
                if case .loaded = transition.state {
                    return true
                } else if case .error = transition.state {
                    return true
                } else {
                    return false
                }
            }
            .assign(to: \.isEnabled, on: refreshButton)
            .store(in: &cancellables)
        
        // Bind start animating
        self.viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transition in
                if case .loading = transition.state {
                    self?.mainView.activityIndicator.startAnimating()
                } else {
                    self?.mainView.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
        
        // Bind inspections
        self.viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transition in
                guard let self = self else { return }

                if case .loaded(let inspections) = transition.state {
                    let calendar = Calendar.current

                    let grouped = Dictionary(grouping: inspections) {
                        calendar.startOfDay(for: $0.inspectionDate ?? .distantPast)
                    }

                    self.groupedInspections = grouped
                        .map { ($0.key, $0.value) }
                        .sorted { $0.0 > $1.0 } // Newest first

                    self.mainView.tableView.reloadData()
                }
            }
            .store(in: &cancellables)

    }

    @objc private func refreshButtonTapped() {
        viewModel.send(input: .refresh)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        groupedInspections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groupedInspections[section].inspections.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
            UITableViewCell(style: .subtitle, reuseIdentifier: "cell")

        let inspection = groupedInspections[indexPath.section].inspections[indexPath.row]
        cell.textLabel?.text = inspection.title
        cell.detailTextLabel?.text = inspection.address
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let date = groupedInspections[section].date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
