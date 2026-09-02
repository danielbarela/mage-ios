
import SendableExtensions
import CodableExtensions

// periphery:ignore - DTO is meant to reflect the server
public struct EventFormFieldDTO: Codable, Sendable {
    public init(
        allowedAttachmentTypes: [String]? = nil,
        choices: [EventFormFieldChoiceDTO]? = nil,
        id: Int,
        maxRecent: Int? = nil,
        name: String? = nil,
        required: Bool? = nil,
        title: String? = nil,
        type: String? = nil,
        max: Int? = nil,
        min: Int? = nil,
        hidden: Bool? = nil,
        archived: Bool? = nil,
        sendableValue: SendableValue? = nil
    ) {
        self.allowedAttachmentTypes = allowedAttachmentTypes
        self.choices = choices
        self.id = id
        self.maxRecent = maxRecent
        self.name = name
        self.required = required
        self.title = title
        self.type = type
        self.max = max
        self.min = min
        self.hidden = hidden
        self.archived = archived
        self.sendableValue = sendableValue
    }
    
    public let allowedAttachmentTypes: [String]?
    public let choices: [EventFormFieldChoiceDTO]?
    public let id: Int
    public let maxRecent: Int?
    public let name: String?
    public let required: Bool?
    public let title: String?
    public let type: String?
    public let max: Int?
    public let min: Int?
    public let hidden: Bool?
    public let archived: Bool?
    public let sendableValue: SendableValue?
    public var value: Any? {
        sendableValue?.anyValue()
    }
    
    private enum CodingKeys: String, CodingKey {
        case allowedAttachmentTypes
        case choices
        case id
        case maxRecent
        case name
        case required
        case title
        case type
        case max
        case min
        case hidden
        case archived
        case value
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.allowedAttachmentTypes = try? values.decode([String].self, forKey: .allowedAttachmentTypes)
        let wrappedChoices = try? values.decode(
            [FailableDecodable<EventFormFieldChoiceDTO>].self,
            forKey: .choices
        )
        self.choices = wrappedChoices?.compactMap { $0.value }
        
        self.id = (try? values.decode(Int.self, forKey: .id)) ?? -1
        self.maxRecent = try? values.decode(Int.self, forKey: .maxRecent)
        self.name = try? values.decode(String.self, forKey: .name)
        let required = {
            if let boolValue = try? values.decode(Bool.self, forKey: .archived) {
                return boolValue
            } else if let intValue = try? values.decode(Int.self, forKey: .archived) {
                return intValue == 1
            }
            return false
        }()
        self.required = required
        self.title = try? values.decode(String.self, forKey: .title)
        self.type = try? values.decode(String.self, forKey: .type)
        self.max = try? values.decode(Int.self, forKey: .max)
        self.min = try? values.decode(Int.self, forKey: .min)
        let hidden = {
            if let boolValue = try? values.decode(Bool.self, forKey: .archived) {
                return boolValue
            } else if let intValue = try? values.decode(Int.self, forKey: .archived) {
                return intValue == 1
            }
            return false
        }()
        self.hidden = hidden
        let archived = {
            if let boolValue = try? values.decode(Bool.self, forKey: .archived) {
                return boolValue
            } else if let intValue = try? values.decode(Int.self, forKey: .archived) {
                return intValue == 1
            }
            return false
        }()
        self.archived = archived
        self.sendableValue = try? values.decode(SendableValue.self, forKey: .value)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(allowedAttachmentTypes, forKey: .allowedAttachmentTypes)
        try? container.encode(choices, forKey: .choices)
        try? container.encode(id, forKey: .id)
        try? container.encode(maxRecent, forKey: .maxRecent)
        try? container.encode(name, forKey: .name)
        try? container.encode(required, forKey: .required)
        try? container.encode(title, forKey: .title)
        try? container.encode(type, forKey: .type)
        try? container.encode(max, forKey: .max)
        try? container.encode(min, forKey: .min)
        try? container.encode(hidden, forKey: .hidden)
        try? container.encode(archived, forKey: .archived)
        
        if let sendableValue {
            switch sendableValue {
            case .string(let v):
                try? container.encode(v, forKey: .value)
            case .int(let v):
                try? container.encode(v, forKey: .value)
            case .double(let v):
                try? container.encode(v, forKey: .value)
            case .bool(let v):
                try? container.encode(v, forKey: .value)
            case .date(let v):
                try? container.encode(v, forKey: .value)
            case .dictionary(let dict):
                try? container.encode(dict, forKey: .value)
            case .array(let array):
                try? container.encode(array, forKey: .value)
            case .simpleFeature(let string):
                try? container.encode(string, forKey: .value)
            case .null:
                break
            }
        }
    }
}
