import Foundation

struct SODAInspection: Codable {
    let title: String
    let address: String
    let inspectionDate: Date
    
    enum CodingKeys: String, CodingKey {
        case title = "dba_name"
        case address = "address"
        case inspectionDate = "inspection_date"
    }
}

class SODAInspectionsLoader: InspectionsLoader {
    private let urlSession: URLSession
    private let decoder: JSONDecoder
    private let baseURL: URL
    
    init(urlSession: URLSession, decoder: JSONDecoder, baseURL: URL) {
        self.urlSession = urlSession
        self.decoder = decoder
        self.baseURL = baseURL
    }
    
    func callAsFunction() async throws -> [Inspection] {
        let (data, _) = try await self.urlSession.data(from: baseURL)
        return try self.decoder.decode([SODAInspection].self, from: data).map { sodaInspection in
                .init(title: sodaInspection.title, address: sodaInspection.address, inspectionDate: sodaInspection.inspectionDate)
        }
    }
}
