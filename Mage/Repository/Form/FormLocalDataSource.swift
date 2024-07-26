//
//  FormLocalDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 7/26/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData
import Combine
import UIKit
import BackgroundTasks
import MagicalRecord
import NSManagedObjectContextExtensions

private struct FormLocalDataSourceProviderKey: InjectionKey {
    static var currentValue: FormLocalDataSource = FormCoreDataDataSource()
}

extension InjectedValues {
    var formLocalDataSource: FormLocalDataSource {
        get { Self[FormLocalDataSourceProviderKey.self] }
        set { Self[FormLocalDataSourceProviderKey.self] = newValue }
    }
}

protocol FormLocalDataSource {
    func getForm(formId: NSNumber) -> Form?
    
}

class FormCoreDataDataSource: CoreDataDataSource, FormLocalDataSource, ObservableObject {
    
    func getForm(formId: NSNumber) -> Form? {
        let context = NSManagedObjectContext.mr_default()
        return context.performAndWait {
            return Form.mr_findFirst(byAttribute: "formId", withValue: formId, in: context)
        }
    }
}
