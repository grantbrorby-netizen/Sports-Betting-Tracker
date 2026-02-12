import Foundation

struct APIErrorResponse: Codable {
    let error: APIErrorDetail
}

struct APIErrorDetail: Codable {
    let code: String
    let message: String
    let details: [String: String]?
}

enum APIError: LocalizedError {
    case unauthorized
    case forbidden
    case notFound
    case rateLimited(String)
    case validation(String)
    case serverError(String)
    case networkError(Error)
    case decodingError(Error)
    case unknown(Int, String)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Please sign in again"
        case .forbidden: return "You don't have access to this feature"
        case .notFound: return "Not found"
        case .rateLimited(let msg): return msg
        case .validation(let msg): return msg
        case .serverError(let msg): return msg
        case .networkError(let err): return "Network error: \(err.localizedDescription)"
        case .decodingError: return "Failed to process server response"
        case .unknown(let code, let msg): return "Error \(code): \(msg)"
        }
    }

    var isRateLimited: Bool {
        if case .rateLimited = self { return true }
        return false
    }
}
