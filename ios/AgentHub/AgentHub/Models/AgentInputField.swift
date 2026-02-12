import Foundation

struct AgentInputField: Codable, Identifiable, Hashable {
    let id: String
    let type: InputFieldType
    let label: String
    var placeholder: String?
    var required: Bool
    var options: [String]?
    var defaultValue: AnyCodableValue?

    enum InputFieldType: String, Codable {
        case text
        case textarea
        case select
        case number
        case toggle
        case photo
    }
}

/// Type-erased Codable value for default values (string, number, bool)
enum AnyCodableValue: Codable, Hashable {
    case string(String)
    case number(Double)
    case bool(Bool)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolVal = try? container.decode(Bool.self) {
            self = .bool(boolVal)
        } else if let doubleVal = try? container.decode(Double.self) {
            self = .number(doubleVal)
        } else if let stringVal = try? container.decode(String.self) {
            self = .string(stringVal)
        } else {
            throw DecodingError.typeMismatch(
                AnyCodableValue.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String, Number, or Bool")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .number(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        }
    }

    var stringValue: String {
        switch self {
        case .string(let v): return v
        case .number(let v): return String(v)
        case .bool(let v): return v ? "true" : "false"
        }
    }
}
