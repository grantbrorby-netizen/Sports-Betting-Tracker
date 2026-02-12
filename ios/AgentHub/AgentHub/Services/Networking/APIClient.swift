import Foundation

actor APIClient {
    static let shared = APIClient()
    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            // Try ISO8601 with fractional seconds first
            if let date = ISO8601DateFormatter.withFractionalSeconds.date(from: dateStr) {
                return date
            }
            if let date = ISO8601DateFormatter.standard.date(from: dateStr) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateStr)")
        }
    }

    // MARK: - Generic request

    func request<T: Decodable>(
        url: URL,
        method: String = "GET",
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppEnvironment.current.supabaseAnonKey, forHTTPHeaderField: "apikey")

        if requiresAuth, let token = await KeychainManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try decoder.decode(T.self, from: data)
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 429:
            let errResp = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.rateLimited(errResp?.error.message ?? "Rate limit exceeded")
        case 400:
            let errResp = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.validation(errResp?.error.message ?? "Bad request")
        default:
            let errResp = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.unknown(httpResponse.statusCode, errResp?.error.message ?? "Unknown error")
        }
    }

    // MARK: - Convenience: POST with body, return data wrapper

    struct DataWrapper<T: Decodable>: Decodable {
        let data: T
    }

    func post<T: Decodable>(url: URL, body: Encodable) async throws -> T {
        let wrapper: DataWrapper<T> = try await request(url: url, method: "POST", body: body)
        return wrapper.data
    }

    func get<T: Decodable>(url: URL) async throws -> T {
        let wrapper: DataWrapper<T> = try await request(url: url)
        return wrapper.data
    }
}

// MARK: - ISO8601 Formatters

extension ISO8601DateFormatter {
    static let withFractionalSeconds: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static let standard: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
