//
//  FormKey.swift
//  Form
//


public enum FormKey : String {
    
    case eventId
    case name
    case primaryField
    case secondaryField = "variantField"
    case primaryFeedField
    case secondaryFeedField
    case color
    case description
    case fields
    case userFields
    case archived
    case id
    case formId
    case min
    case max
    case style
    case isDefault = "default"
    
    public var key: String {
        return self.rawValue
    }
}
