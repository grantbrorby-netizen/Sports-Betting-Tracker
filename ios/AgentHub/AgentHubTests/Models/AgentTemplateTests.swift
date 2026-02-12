import XCTest
@testable import AgentHub

final class AgentTemplateTests: XCTestCase {

    // MARK: - JSON Decoding

    func testDecodesFromSnakeCaseJSON() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "template_id": "email-writer",
            "name": "Email Writer",
            "description": "Writes professional emails",
            "category": "writing",
            "icon_name": "envelope.fill",
            "system_prompt": "Write an email about {{topic}}.",
            "input_schema": [
                {
                    "id": "topic",
                    "type": "text",
                    "label": "Topic",
                    "placeholder": "What's the email about?",
                    "required": true
                }
            ],
            "output_format": "markdown",
            "default_model_tier": "fast",
            "requires_vision": false,
            "max_tokens": 1024,
            "temperature": 0.7,
            "is_featured": true,
            "is_public": true,
            "version": "1.0.0",
            "author": "AgentHub",
            "created_at": "2026-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let template = try decoder.decode(AgentTemplate.self, from: json)

        XCTAssertEqual(template.templateId, "email-writer")
        XCTAssertEqual(template.name, "Email Writer")
        XCTAssertEqual(template.category, "writing")
        XCTAssertEqual(template.iconName, "envelope.fill")
        XCTAssertEqual(template.defaultModelTier, "fast")
        XCTAssertEqual(template.requiresVision, false)
        XCTAssertEqual(template.maxTokens, 1024)
        XCTAssertEqual(template.temperature, 0.7)
        XCTAssertEqual(template.isFeatured, true)
        XCTAssertEqual(template.isPublic, true)
        XCTAssertEqual(template.version, "1.0.0")
        XCTAssertEqual(template.author, "AgentHub")
        XCTAssertNil(template.isInstalled)
    }

    func testDecodesWithIsInstalled() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "template_id": "test",
            "name": "Test",
            "description": "A test",
            "category": "writing",
            "icon_name": "doc",
            "system_prompt": "Test",
            "input_schema": [],
            "output_format": "text",
            "default_model_tier": "fast",
            "requires_vision": false,
            "max_tokens": 512,
            "temperature": 0.5,
            "is_featured": false,
            "is_public": true,
            "version": "1.0.0",
            "author": "Test",
            "created_at": "2026-01-15T10:00:00Z",
            "is_installed": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let template = try decoder.decode(AgentTemplate.self, from: json)

        XCTAssertEqual(template.isInstalled, true)
    }

    // MARK: - Input Schema Decoding

    func testDecodesInputFields() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "template_id": "recipe-helper",
            "name": "Recipe Helper",
            "description": "Helps with recipes",
            "category": "cooking",
            "icon_name": "fork.knife",
            "system_prompt": "Create a recipe for {{dish}}",
            "input_schema": [
                {
                    "id": "dish",
                    "type": "text",
                    "label": "Dish Name",
                    "placeholder": "e.g., pasta",
                    "required": true
                },
                {
                    "id": "servings",
                    "type": "number",
                    "label": "Servings",
                    "required": false,
                    "defaultValue": 4
                },
                {
                    "id": "dietary",
                    "type": "select",
                    "label": "Dietary Preference",
                    "required": false,
                    "options": ["none", "vegetarian", "vegan", "gluten-free"]
                }
            ],
            "output_format": "markdown",
            "default_model_tier": "fast",
            "requires_vision": false,
            "max_tokens": 2048,
            "temperature": 0.8,
            "is_featured": false,
            "is_public": true,
            "version": "1.0.0",
            "author": "AgentHub",
            "created_at": "2026-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let template = try decoder.decode(AgentTemplate.self, from: json)

        XCTAssertEqual(template.inputSchema.count, 3)
        XCTAssertEqual(template.inputSchema[0].id, "dish")
        XCTAssertEqual(template.inputSchema[0].type, .text)
        XCTAssertEqual(template.inputSchema[0].required, true)
        XCTAssertEqual(template.inputSchema[1].type, .number)
        XCTAssertEqual(template.inputSchema[1].defaultValue?.stringValue, "4.0")
        XCTAssertEqual(template.inputSchema[2].type, .select)
        XCTAssertEqual(template.inputSchema[2].options?.count, 4)
    }

    // MARK: - Computed Properties

    func testCategoryDisplayName() throws {
        let json = makeTemplateJSON(category: "writing")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let template = try decoder.decode(AgentTemplate.self, from: json)

        XCTAssertEqual(template.categoryDisplayName, "Writing")
    }

    // MARK: - Equatable / Hashable

    func testEqualityBasedOnId() throws {
        let json1 = makeTemplateJSON(name: "Template A")
        let json2 = makeTemplateJSON(name: "Template B") // Same UUID, different name

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let t1 = try decoder.decode(AgentTemplate.self, from: json1)
        let t2 = try decoder.decode(AgentTemplate.self, from: json2)

        XCTAssertEqual(t1, t2, "Templates with same ID should be equal")
    }

    func testHashConsistency() throws {
        let json = makeTemplateJSON()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let template = try decoder.decode(AgentTemplate.self, from: json)

        var hasher1 = Hasher()
        template.hash(into: &hasher1)
        let hash1 = hasher1.finalize()

        var hasher2 = Hasher()
        template.hash(into: &hasher2)
        let hash2 = hasher2.finalize()

        XCTAssertEqual(hash1, hash2)
    }

    // MARK: - AnyCodableValue

    func testAnyCodableStringDecoding() throws {
        let json = """
        "hello"
        """.data(using: .utf8)!
        let value = try JSONDecoder().decode(AnyCodableValue.self, from: json)
        XCTAssertEqual(value, .string("hello"))
        XCTAssertEqual(value.stringValue, "hello")
    }

    func testAnyCodableNumberDecoding() throws {
        let json = "42.5".data(using: .utf8)!
        let value = try JSONDecoder().decode(AnyCodableValue.self, from: json)
        XCTAssertEqual(value, .number(42.5))
        XCTAssertEqual(value.stringValue, "42.5")
    }

    func testAnyCodableBoolDecoding() throws {
        let json = "true".data(using: .utf8)!
        let value = try JSONDecoder().decode(AnyCodableValue.self, from: json)
        XCTAssertEqual(value, .bool(true))
        XCTAssertEqual(value.stringValue, "true")
    }

    // MARK: - Helpers

    private func makeTemplateJSON(category: String = "writing", name: String = "Test") -> Data {
        """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "template_id": "test",
            "name": "\(name)",
            "description": "A test",
            "category": "\(category)",
            "icon_name": "doc",
            "system_prompt": "Test",
            "input_schema": [],
            "output_format": "text",
            "default_model_tier": "fast",
            "requires_vision": false,
            "max_tokens": 512,
            "temperature": 0.5,
            "is_featured": false,
            "is_public": true,
            "version": "1.0.0",
            "author": "Test",
            "created_at": "2026-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!
    }
}
