//
//  Form.m
//  mage-ios-sdk
//
//

import Foundation
import ZipArchive
import CoreData

import Persistence

extension Form {
    
    @objc public static let MAGEFormFetched = "mil.nga.giat.mage.form.fetched";
    
    @discardableResult
    @objc public static func deleteAllFormsForEvent(eventId: NSNumber, context: NSManagedObjectContext) -> Bool {
        return Form.mr_deleteAll(matching: NSPredicate(format: "eventId == %@", eventId), in: context)
    }
    
    @discardableResult
    @objc public static func createForm(eventId: NSNumber, order: NSNumber, formJson: [AnyHashable : Any], context: NSManagedObjectContext) -> Form? {
        if let formId = formJson[FormKey.id.key] as? NSNumber, let form = Form.mr_createEntity(in: context), let formJsonEntity = FormJson.mr_createEntity(in: context) {
            formJsonEntity.json = formJson
            formJsonEntity.formId = formId
            form.json = formJsonEntity
            form.eventId = eventId
            form.archived = formJson[FormKey.archived.key] as? Bool ?? false
            form.formId = formId
            form.order = order
            
            if let formFields = formJson[FormKey.fields.key] as? [[AnyHashable: Any]] {
                if let primaryMapFieldName = formJson[FormKey.primaryField.key] as? String {
                    form.primaryMapField = formFields.first { field in
                        if let fieldName = field[FieldKey.name.key] as? String {
                            return fieldName == primaryMapFieldName
                        }
                        return false
                    }
                }
                if let secondaryMapFieldName = formJson[FormKey.secondaryField.key] as? String {
                    form.secondaryMapField = formFields.first { field in
                        if let fieldName = field[FieldKey.name.key] as? String {
                            return fieldName == secondaryMapFieldName
                        }
                        return false
                    }
                }
                if let primaryFeedFieldName = formJson[FormKey.primaryFeedField.key] as? String {
                    form.primaryFeedField = formFields.first { field in
                        if let fieldName = field[FieldKey.name.key] as? String {
                            return fieldName == primaryFeedFieldName
                        }
                        return false
                    }
                }
                if let secondaryFeedFieldName = formJson[FormKey.secondaryFeedField.key] as? String {
                    form.secondaryFeedField = formFields.first { field in
                        if let fieldName = field[FieldKey.name.key] as? String {
                            return fieldName == secondaryFeedFieldName
                        }
                        return false
                    }
                }
            }
            
            return form
        }
        return nil
    }
    
    @discardableResult
    @objc public static func deleteAndRecreateForms(eventId: NSNumber, formsJson:[[AnyHashable: Any]], context: NSManagedObjectContext) -> [Form] {
        Form.deleteAllFormsForEvent(eventId: eventId, context: context)
        var forms: [Form] = []
        for (index, formJson) in formsJson.enumerated() {
            if let form = Form.createForm(eventId: eventId, order: NSNumber(value: index), formJson: formJson, context: context) {
                forms.append(form)
            }
        }
        return forms
    }
    
    @objc public var name: String? {
        get {
            return json?.json?[FormKey.name.key] as? String
        }
    }
    
    @objc public var formDescription: String? {
        get {
            return json?.json?[FormKey.description.key] as? String
        }
    }
    
    @objc public var fields: [[String: AnyHashable]]? {
        get {
            return json?.json?[FormKey.fields.key] as? [[String: AnyHashable]]
        }
    }
    
    public var min: Int? {
        get {
            return json?.json?[FormKey.min.key] as? Int
        }
    }
    
    public var max: Int? {
        get {
            return json?.json?[FormKey.max.key] as? Int
        }
    }
    
    public var isDefault: Bool {
        get {
            return json?.json?[FormKey.isDefault.key] as? Bool ?? false
        }
    }
    
    @objc public var color: String? {
        get {
            return json?.json?[FormKey.color.key] as? String
        }
    }
    
    @objc public var style: [AnyHashable:Any]? {
        get {
            return json?.json?[FormKey.style.key] as? [AnyHashable:Any]
        }
    }
    
    @objc public func getFieldByName(name: String) -> [String: AnyHashable]? {
        if let fields = json?.json?[FormKey.fields.key] as? [[String: AnyHashable]] {
            return fields.first { field in
                field[FieldKey.name.key] as? String == name
            }
        }
        return nil
    }
    
    static func getFieldByNameFromJSONFields(json: [[String: AnyHashable]], name: String) -> [String: AnyHashable]? {
        return json.first { field in
            field[FieldKey.name.key] as? String == name
        }
    }
    
    static func getDocumentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as String
    }
}
