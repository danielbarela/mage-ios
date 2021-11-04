//
//  FieldKey.swift
//  MAGE
//
//  Created by Daniel Barela on 5/25/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public enum FieldKey : String {
    
    case title
    case type
    case required
    case id
    case name
    case choices
    case value
    case min
    case max
    case archived
    case hidden
    case allowedAttachmentTypes
    
    var key: String {
        return self.rawValue
    }
}

public enum EventKey : String {
    
    case id
    case forms
    case name
    case description
    case formId
    case remoteId
    case teams
    case maxObservationForms
    case minObservationForms
    case acl
    case layers
    
    var key: String {
        return self.rawValue
    }
}

public enum FormKey : String {
    
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
    
    var key: String {
        return self.rawValue
    }
}

public enum ObservationKey : String {
    
    case forms
    case accuracy
    case provider
    case delta
    case timestamp
    case geometry
    case important
    case lastModified
    case remoteId
    case favoriteUserIds
    case attachments
    case userId
    case deviceId
    case url
    case id
    case properties
    case type
    case state
    case eventId
    
    var key: String {
        return self.rawValue
    }
}

public enum AttachmentKey : String {
    case contentType
    case name
    case remotePath
    case size
    case url
    case id
    case action
    
    var key: String {
        return self.rawValue
    }
}

public enum TeamKey : String {
    case id
    case name
    case description
    case userIds
    case remoteId
    
    var key: String {
        return self.rawValue
    }
}

public enum UserKey : String {
    case remoteId
    case id
    case username
    case email
    case displayName
    case phones
    case number
    case iconUrl
    case icon
    case avatarUrl
    case recentEventIds
    case createdAt
    case lastUpdated
    case role
    case locations
    
    var key: String {
        return self.rawValue
    }
}

public enum UserPhoneKey : String {
    case number
    
    var key: String {
        return self.rawValue
    }
}

public enum UserIconKey : String {
    case text
    case color
    
    var key: String {
        return self.rawValue
    }
}

public enum RoleKey : String {
    case id
    case remoteId
    case permissions
    
    var key: String {
        return self.rawValue;
    }
}

public enum PermissionsKey: String {
    case permissions
    
    case update
    case DELETE_OBSERVATION
    case UPDATE_EVENT
    case UPDATE_OBSERVATION_ALL
    case UPDATE_OBSERVATION_EVENT
    
    var key: String {
        return self.rawValue
    }
}

public enum FieldType : String {
    
    case attachment
    case numberfield
    case textfield
    case textarea
    case email
    case password
    case date
    case checkbox
    case dropdown
    case geometry
    case radio
    case multiselectdropdown
    case hidden
    
    var key: String {
        return self.rawValue
    }
}

public enum LocationKey : String {
    
    case id
    case type
    case eventId
    case properties
    case timestamp
    case geometry
    case user
    
    var key : String {
        return self.rawValue
    }
}

public enum GPSLocationKey : String {
    case altitude
    case accuracy
    case verticalAccuracy
    case bearing
    case speed
    case millis
    case timestamp
    case battery_level
    case battery_state
    case telephone_network
    case carrier_information
    case carrier_name
    case country_code
    case mobile_country_code
    case network
    case mage_version
    case provider
    case system_version
    case system_name
    case device_name
    case device_model
    
    var key : String {
        return self.rawValue;
    }
}

public enum FeedKey : String {
    
    case eventId
    case itemsHaveSpatialDimension
    case remoteId
    case items
    case features
    case id
    case title
    case summary
    case constantParams
    case variableParams
    case updateFrequency
    case mapStyle
    case itemPropertiesSchema
    case itemPrimaryProperty
    case itemSecondaryProperty
    case itemTemporalProperty
    case itemsHaveIdentity
    
    var key : String {
        return self.rawValue
    }
}

public enum FeedItemKey : String {
    
    case geometry
    case properties
    case id
    case remoteId
    
    var key : String {
        return self.rawValue
    }
}

public enum FeedItemPropertiesSchemaKey : String {
    case properties
    case type
    case number
    case format
    case date
    
    var key : String {
        return self.rawValue;
    }
}

public enum FeedMapStyleKey : String {
    case icon
    case id
    
    var key : String {
        return self.rawValue;
    }
}
